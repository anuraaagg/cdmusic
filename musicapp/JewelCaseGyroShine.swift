import CoreMotion
import SwiftUI

// MARK: - Motion model (Apple Cash–style focal point from device attitude)

/// Tracks pitch/roll deltas and maps them to a moving light focal point on the jewel case.
/// Adapted from [Apple-Cash-Animation](https://github.com/jtrivedi/Apple-Cash-Animation).
@MainActor
final class JewelCaseMotionShineModel: ObservableObject {
    @Published private(set) var focalPoint: CGPoint = .zero

    private let motionManager = CMMotionManager()
    private var initialPitch: Double?
    private var initialRoll: Double?
    private var isRunning = false

    private var originFocalPoint: CGPoint = .zero

    func configure(size: CGSize) {
        originFocalPoint = CGPoint(x: size.width * 0.5, y: size.height * 0.92)
        focalPoint = originFocalPoint
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

            let maxRadiansX = 0.35
            let maxRadiansY = 0.22
            let maxAdjustment = originFocalPoint.x * 0.92

            let yAdjustment = mapRange(deltaPitch, -maxRadiansY, maxRadiansY, -maxAdjustment, maxAdjustment)
            let xAdjustment = mapRange(deltaRoll, -maxRadiansX, maxRadiansX, -maxAdjustment, maxAdjustment)

            focalPoint = CGPoint(
                x: originFocalPoint.x + xAdjustment,
                y: originFocalPoint.y + yAdjustment
            )
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

// MARK: - Shine overlay

struct JewelCaseGyroShineOverlay: View {
    let focalPoint: CGPoint
    let size: CGFloat

    private var focalUnit: UnitPoint {
        UnitPoint(x: focalPoint.x / size, y: focalPoint.y / size)
    }

    private var sweepAngle: Angle {
        let dx = focalPoint.x - size * 0.5
        let dy = focalPoint.y - size * 0.55
        return .radians(atan2(dy, dx))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let drift = timeline.date.timeIntervalSinceReferenceDate * 12

            ZStack {
                AngularGradient(
                    stops: Self.rainbowStops,
                    center: focalUnit,
                    startAngle: sweepAngle + .degrees(drift),
                    endAngle: sweepAngle + .degrees(drift + 360)
                )
                .opacity(0.28)
                .blendMode(.softLight)

                Canvas { context, canvasSize in
                    drawRainbowField(
                        in: &context,
                        size: canvasSize,
                        focal: focalPoint,
                        dotStep: max(16, size * 0.048)
                    )
                }
                .opacity(0.55)
                .blendMode(.softLight)

                RadialGradient(
                    stops: [
                        .init(color: .white.opacity(0.38), location: 0),
                        .init(color: Color(hue: 0.58, saturation: 0.35, brightness: 1).opacity(0.16), location: 0.4),
                        .init(color: .white.opacity(0), location: 1),
                    ],
                    center: focalUnit,
                    startRadius: 0,
                    endRadius: size * 0.32
                )
                .blendMode(.plusLighter)

                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.28), location: 0.5),
                        .init(color: .white.opacity(0), location: 1),
                    ],
                    startPoint: UnitPoint(x: 0.5 - cos(sweepAngle.radians) * 0.5, y: 0.5 - sin(sweepAngle.radians) * 0.5),
                    endPoint: UnitPoint(x: 0.5 + cos(sweepAngle.radians) * 0.5, y: 0.5 + sin(sweepAngle.radians) * 0.5)
                )
                .opacity(0.22)
                .blendMode(.plusLighter)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .animation(nil, value: focalPoint.x)
        .animation(nil, value: focalPoint.y)
    }

    private static let rainbowStops: [Gradient.Stop] = [
        .init(color: Color(hue: 0.00, saturation: 0.95, brightness: 1), location: 0.00),
        .init(color: Color(hue: 0.10, saturation: 0.95, brightness: 1), location: 0.14),
        .init(color: Color(hue: 0.18, saturation: 0.95, brightness: 1), location: 0.28),
        .init(color: Color(hue: 0.33, saturation: 0.90, brightness: 1), location: 0.42),
        .init(color: Color(hue: 0.52, saturation: 0.92, brightness: 1), location: 0.57),
        .init(color: Color(hue: 0.66, saturation: 0.92, brightness: 1), location: 0.71),
        .init(color: Color(hue: 0.78, saturation: 0.92, brightness: 1), location: 0.85),
        .init(color: Color(hue: 0.92, saturation: 0.95, brightness: 1), location: 1.00),
    ]

    private func drawRainbowField(
        in context: inout GraphicsContext,
        size: CGSize,
        focal: CGPoint,
        dotStep: CGFloat
    ) {
        let cols = Int(ceil(size.width / dotStep))
        let rows = Int(ceil(size.height / dotStep))
        let minHue = 0.0
        let maxHue = 1.0
        let radiusForMaxHue = size.width * 1.05

        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * dotStep + dotStep * 0.5
                let y = CGFloat(row) * dotStep + dotStep * 0.5
                let distance = hypot(x - focal.x, y - focal.y)

                let hue = clipUnit(mapRange(distance, 0, radiusForMaxHue, minHue, maxHue))
                let alpha = clipUnit(mapRange(distance, dotStep, radiusForMaxHue * 0.72, 0.34, 0.06))
                let dotSize = dotStep * clipUnit(mapRange(distance, 0, radiusForMaxHue * 0.5, 1.05, 0.55))

                let rect = CGRect(
                    x: x - dotSize * 0.5,
                    y: y - dotSize * 0.5,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color(hue: hue, saturation: 0.62, brightness: 1).opacity(alpha))
                )
            }
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
