import CoreMotion
import SwiftUI

// MARK: - Motion model (Apple Cash–style focal point from device attitude)

/// Tracks pitch/roll deltas and maps them to a moving light focal point on the jewel case.
/// Adapted from [Apple-Cash-Animation](https://github.com/jtrivedi/Apple-Cash-Animation).
@MainActor
final class JewelCaseMotionShineModel: ObservableObject {
    @Published private(set) var focalPoint: CGPoint = .zero
    /// 0…1 — grows as the phone tilts, drives shimmer intensity.
    @Published private(set) var tiltAmount: CGFloat = 0

    private let motionManager = CMMotionManager()
    private var initialPitch: Double?
    private var initialRoll: Double?
    private var isRunning = false

    private var caseSize: CGSize = .zero
    private var originFocalPoint: CGPoint = .zero
    private var displayFocalPoint: CGPoint = .zero

    func configure(size: CGSize) {
        caseSize = size
        originFocalPoint = CGPoint(x: size.width * 0.5, y: size.height * 0.50)
        displayFocalPoint = originFocalPoint
        focalPoint = originFocalPoint
        tiltAmount = 0
    }

    func start() {
        guard !isRunning, motionManager.isDeviceMotionAvailable else { return }
        isRunning = true
        initialPitch = nil
        initialRoll = nil

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryCorrectedZVertical,
            to: .main
        ) { [weak self] data, _ in
            guard let self, let attitude = data?.attitude else { return }

            if initialPitch == nil { initialPitch = attitude.pitch }
            if initialRoll == nil { initialRoll = attitude.roll }

            guard let initialPitch, let initialRoll else { return }

            let deltaPitch = attitude.pitch - initialPitch
            let deltaRoll = attitude.roll - initialRoll

            let maxRadiansX = 0.28
            let maxRadiansY = 0.20
            let maxAdjustmentX = caseSize.width * 0.44
            let maxAdjustmentY = caseSize.height * 0.38

            // tanh gives smooth response — no hard clamping at edges.
            let xAdjustment = CGFloat(tanh(deltaRoll / maxRadiansX)) * maxAdjustmentX
            let yAdjustment = CGFloat(tanh(deltaPitch / maxRadiansY)) * maxAdjustmentY

            let target = CGPoint(
                x: originFocalPoint.x + xAdjustment,
                y: originFocalPoint.y + yAdjustment
            )

            let follow: CGFloat = 0.38
            displayFocalPoint = CGPoint(
                x: displayFocalPoint.x + (target.x - displayFocalPoint.x) * follow,
                y: displayFocalPoint.y + (target.y - displayFocalPoint.y) * follow
            )
            focalPoint = displayFocalPoint

            let tilt = hypot(deltaRoll / maxRadiansX, deltaPitch / maxRadiansY)
            tiltAmount = CGFloat(min(1, tilt * 0.85))
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
        initialPitch = nil
        initialRoll = nil
    }
}

// MARK: - Dot layout cache

private enum JewelCaseShineDotLayout {
    static func centers(for size: CGFloat) -> [CGPoint] {
        if let cached = cache[size] { return cached }
        let dotStep = max(16, size * 0.048)
        let cols = Int(ceil(size / dotStep))
        let rows = Int(ceil(size / dotStep))
        var centers: [CGPoint] = []
        centers.reserveCapacity(cols * rows)

        for row in 0..<rows {
            for col in 0..<cols {
                centers.append(CGPoint(
                    x: CGFloat(col) * dotStep + dotStep * 0.5,
                    y: CGFloat(row) * dotStep + dotStep * 0.5
                ))
            }
        }

        cache[size] = centers
        return centers
    }

    private static var cache: [CGFloat: [CGPoint]] = [:]
}

// MARK: - Shine overlay

struct JewelCaseGyroShineOverlay: View {
    let focalPoint: CGPoint
    let size: CGFloat
    var tiltAmount: CGFloat = 0
    var palette: JewelCaseShinePalette = .rainbow

    private var focalUnit: UnitPoint {
        UnitPoint(x: focalPoint.x / size, y: focalPoint.y / size)
    }

    private var sweepAngle: Angle {
        let dx = focalPoint.x - size * 0.5
        let dy = focalPoint.y - size * 0.5
        return .radians(atan2(dy, dx))
    }

    private var dotCenters: [CGPoint] {
        JewelCaseShineDotLayout.centers(for: size)
    }

    private var dotStep: CGFloat {
        max(16, size * 0.048)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let drift = t * 10
            let breathe = 0.5 + 0.5 * sin(t * 1.6)

            ZStack {
                AngularGradient(
                    stops: palette.gradientStops,
                    center: focalUnit,
                    startAngle: sweepAngle + .degrees(drift),
                    endAngle: sweepAngle + .degrees(drift + 360)
                )
                .opacity(0.34 + tiltAmount * 0.10)
                .blendMode(.softLight)

                Canvas { context, canvasSize in
                    drawRainbowField(
                        in: &context,
                        size: canvasSize,
                        focal: focalPoint
                    )
                }
                .opacity(0.58 + tiltAmount * 0.12)
                .blendMode(.softLight)

                gyroShimmerLayer(drift: drift, breathe: breathe)

                RadialGradient(
                    stops: [
                        .init(color: .white.opacity(0.44 + tiltAmount * 0.14), location: 0),
                        .init(color: Color(hue: palette.accentHue, saturation: 0.38, brightness: 1).opacity(0.20), location: 0.38),
                        .init(color: .white.opacity(0), location: 1),
                    ],
                    center: focalUnit,
                    startRadius: 0,
                    endRadius: size * 0.28
                )
                .blendMode(.plusLighter)

                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.32 + tiltAmount * 0.12), location: 0.5),
                        .init(color: .white.opacity(0), location: 1),
                    ],
                    startPoint: UnitPoint(x: 0.5 - cos(sweepAngle.radians) * 0.5, y: 0.5 - sin(sweepAngle.radians) * 0.5),
                    endPoint: UnitPoint(x: 0.5 + cos(sweepAngle.radians) * 0.5, y: 0.5 + sin(sweepAngle.radians) * 0.5)
                )
                .opacity(0.26 + tiltAmount * 0.10)
                .blendMode(.plusLighter)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(nil, value: focalPoint.x)
        .animation(nil, value: focalPoint.y)
        .animation(nil, value: tiltAmount)
        .animation(.easeInOut(duration: 0.45), value: palette)
    }

    /// Subtle holographic streaks that follow gyro + a slow ambient drift.
    @ViewBuilder
    private func gyroShimmerLayer(drift: Double, breathe: Double) -> some View {
        let shimmerOpacity = 0.14 + tiltAmount * 0.16 + breathe * 0.04
        let bandAngle = sweepAngle + .degrees(drift * 0.35)

        ZStack {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.10), location: 0.42),
                    .init(color: .white.opacity(0.22), location: 0.50),
                    .init(color: .white.opacity(0.10), location: 0.58),
                    .init(color: .clear, location: 1),
                ],
                startPoint: UnitPoint(
                    x: 0.5 - cos(bandAngle.radians) * 0.72,
                    y: 0.5 - sin(bandAngle.radians) * 0.72
                ),
                endPoint: UnitPoint(
                    x: 0.5 + cos(bandAngle.radians) * 0.72,
                    y: 0.5 + sin(bandAngle.radians) * 0.72
                )
            )
            .blendMode(.plusLighter)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(hue: palette.accentHue, saturation: 0.55, brightness: 1).opacity(0.08), location: 0.46),
                    .init(color: Color(hue: palette.accentHue + 0.06, saturation: 0.50, brightness: 1).opacity(0.14), location: 0.50),
                    .init(color: Color(hue: palette.accentHue, saturation: 0.55, brightness: 1).opacity(0.08), location: 0.54),
                    .init(color: .clear, location: 1),
                ],
                startPoint: UnitPoint(
                    x: focalUnit.x - cos(bandAngle.radians + .pi / 2) * 0.55,
                    y: focalUnit.y - sin(bandAngle.radians + .pi / 2) * 0.55
                ),
                endPoint: UnitPoint(
                    x: focalUnit.x + cos(bandAngle.radians + .pi / 2) * 0.55,
                    y: focalUnit.y + sin(bandAngle.radians + .pi / 2) * 0.55
                )
            )
            .blendMode(.softLight)

            Canvas { context, canvasSize in
                drawShimmerStreaks(
                    in: &context,
                    size: canvasSize,
                    focal: focalPoint,
                    angle: bandAngle.radians + drift * 0.02
                )
            }
            .blendMode(.plusLighter)
        }
        .opacity(shimmerOpacity)
    }

    private func drawShimmerStreaks(
        in context: inout GraphicsContext,
        size: CGSize,
        focal: CGPoint,
        angle: Double
    ) {
        let streakCount = 6
        let span = size.width * 1.1
        let normal = CGPoint(x: cos(angle + .pi / 2), y: sin(angle + .pi / 2))

        for i in 0..<streakCount {
            let offset = (CGFloat(i) - CGFloat(streakCount - 1) * 0.5) * size.width * 0.11
            let cx = focal.x + normal.x * offset
            let cy = focal.y + normal.y * offset
            let along = CGPoint(x: cos(angle), y: sin(angle))
            let half = span * 0.5

            var path = Path()
            path.move(to: CGPoint(x: cx - along.x * half, y: cy - along.y * half))
            path.addLine(to: CGPoint(x: cx + along.x * half, y: cy + along.y * half))

            let alpha = 0.04 + Double(i % 2) * 0.025 + Double(tiltAmount) * 0.05
            context.stroke(
                path,
                with: .color(Color(hue: palette.accentHue + Double(i) * 0.02, saturation: 0.35, brightness: 1).opacity(alpha)),
                lineWidth: 0.8
            )
        }
    }

    private func drawRainbowField(
        in context: inout GraphicsContext,
        size: CGSize,
        focal: CGPoint
    ) {
        let radiusForMaxHue = size.width * 0.88
        let nearRadius = radiusForMaxHue * 0.50
        let sizeRadius = radiusForMaxHue * 0.36
        let step = dotStep

        for center in dotCenters {
            let distance = hypot(center.x - focal.x, center.y - focal.y)
            let normalized = clipUnit(mapRange(distance, 0, radiusForMaxHue, 0, 1))
            let hue = palette.hue(forNormalizedDistance: Double(normalized))
            let alpha = clipUnit(mapRange(distance, step * 0.5, nearRadius, 0.46 + tiltAmount * 0.10, 0.04))
            let dotSize = step * clipUnit(mapRange(distance, 0, sizeRadius, 1.15, 0.5))

            let rect = CGRect(
                x: center.x - dotSize * 0.5,
                y: center.y - dotSize * 0.5,
                width: dotSize,
                height: dotSize
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(Color(hue: hue, saturation: 0.68, brightness: 1).opacity(alpha))
            )
        }
    }
}

// MARK: - Helpers

private func mapRange<T: FloatingPoint>(_ value: T, _ inMin: T, _ inMax: T, _ outMin: T, _ outMax: T) -> T {
    (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
}

private func clipUnit<T: FloatingPoint>(_ value: T) -> T {
    min(1, max(0, value))
}
