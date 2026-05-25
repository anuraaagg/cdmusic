import SwiftUI
import UIKit

// MARK: - FigmaJogWheel
//
// Music transport only — Figma `332:4666`.
//
// | Zone            | Gesture              | Action                          |
// |-----------------|----------------------|---------------------------------|
// | Inner cap       | Tap                  | Play / pause                    |
// | Inner cap       | Push ↑ / →           | Seek +10 s in current track     |
// | Inner cap       | Push ↓ / ←           | Seek −10 s in current track     |
// | Outer platter   | Rotate               | Scrub position + scratch CD     |
// | Outer platter   | Flick                | Inertia scratch (CD keeps spin) |
// | Outer platter   | Rotate ≥ 60°         | Skip to next / previous track   |
//
// Does NOT control volume, library, crates panel, or settings.

struct FigmaJogWheel<CapExtras: View>: View {
    var diameter: CGFloat = FigmaTheme.jogWheelDiameter

    @Binding var rotation: Double

    var isPlaying: Bool = false
    var isActive: Bool = false
    var innerPressed: Bool = false

    var showIndicator: Bool = true
    var enableHaptics: Bool = true

    /// Extra procedural content above the tactile layer (normally empty).
    @ViewBuilder var capOverlayAboveTactile: () -> CapExtras

    var onCenterTap: () -> Void
    /// Outer platter — skip to next track after a large rotation.
    var onSnapForward: () -> Void
    /// Outer platter — skip to previous track after a large rotation.
    var onSnapBack: () -> Void
    /// Inner cap — nudge forward within the current track.
    var onJiggleSeekForward: () -> Void
    /// Inner cap — nudge backward within the current track.
    var onJiggleSeekBack: () -> Void
    /// Called once when an outer-platter drag begins — use to capture seek anchor.
    var onJogBegin: () -> Void
    /// Degrees rotated from drag origin on the outer platter.
    var onScrub: (Double) -> Void
    var onScrubEnd: () -> Void
    var onScratchDelta: ((Double, Double) -> Void)?
    var onScratchEnd: (() -> Void)?

    var detentAngle: Double = 15
    var snapAngle: Double = 60
    var friction: Double = 0.94
    var stopVelocity: Double = 0.06

    /// Normalised joystick travel (fraction of knob diameter).
    var jiggleTravel: CGFloat = 0.13

    // Internal state ---------------------------------------------------------

    private enum DragMode { case jiggle, jog }

    @State private var dragMode: DragMode?
    @State private var dragStartAngle: Double?
    @State private var dragStartRot = 0.0
    @State private var burst = 0.0
    @State private var lastAngle: Double?
    @State private var lastTime: Date?
    @State private var lastDetentMark = 0.0
    @State private var velocitySamples: [(t: Date, r: Double)] = []
    @State private var isDragging = false

    @State private var spinVelocity = 0.0
    @State private var spinTimer: Timer?

    /// Cap deflection from centre (drag in **inner** joystick zone).
    @State private var jiggleDisplay: CGSize = .zero
    @State private var wasJiggleDragging = false
    @State private var lastEdgeHaptic: Date = .distantPast

    private let hapticDetent = UIImpactFeedbackGenerator(style: .light)
    private let hapticSnap = UIImpactFeedbackGenerator(style: .medium)
    private let hapticGrab = UIImpactFeedbackGenerator(style: .rigid)
    private let hapticSoft = UIImpactFeedbackGenerator(style: .soft)

    init(
        diameter: CGFloat = FigmaTheme.jogWheelDiameter,
        rotation: Binding<Double>,
        isPlaying: Bool = false,
        isActive: Bool = false,
        innerPressed: Bool = false,
        showIndicator: Bool = true,
        enableHaptics: Bool = true,
        detentAngle: Double = 15,
        snapAngle: Double = 60,
        friction: Double = 0.94,
        stopVelocity: Double = 0.06,
        jiggleTravel: CGFloat = 0.13,
        onCenterTap: @escaping () -> Void,
        onSnapForward: @escaping () -> Void,
        onSnapBack: @escaping () -> Void,
        onJiggleSeekForward: @escaping () -> Void,
        onJiggleSeekBack: @escaping () -> Void,
        onJogBegin: @escaping () -> Void = {},
        onScrub: @escaping (Double) -> Void,
        onScrubEnd: @escaping () -> Void,
        onScratchDelta: ((Double, Double) -> Void)? = nil,
        onScratchEnd: (() -> Void)? = nil,
        @ViewBuilder capOverlayAboveTactile: @escaping () -> CapExtras
    ) {
        self.diameter = diameter
        self._rotation = rotation
        self.isPlaying = isPlaying
        self.isActive = isActive
        self.innerPressed = innerPressed
        self.showIndicator = showIndicator
        self.enableHaptics = enableHaptics
        self.detentAngle = detentAngle
        self.snapAngle = snapAngle
        self.friction = friction
        self.stopVelocity = stopVelocity
        self.jiggleTravel = jiggleTravel
        self.onCenterTap = onCenterTap
        self.onSnapForward = onSnapForward
        self.onSnapBack = onSnapBack
        self.onJiggleSeekForward = onJiggleSeekForward
        self.onJiggleSeekBack = onJiggleSeekBack
        self.onJogBegin = onJogBegin
        self.onScrub = onScrub
        self.onScrubEnd = onScrubEnd
        self.onScratchDelta = onScratchDelta
        self.onScratchEnd = onScratchEnd
        self.capOverlayAboveTactile = capOverlayAboveTactile
    }

    var body: some View {
        let maxJ = max(4, diameter * jiggleTravel)
        let jiggleZoneR = diameter * 0.22

        FigmaKnob3324666(
            diameter: diameter,
            capJiggle: jiggleDisplay,
            shadowParallaxScale: 0.28,
            innerPressed: innerPressed
        ) {
            ZStack {
                rotatingLayer
                capOverlayAboveTactile()
            }
            .frame(width: diameter, height: diameter)
            .allowsHitTesting(false)
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .gesture(wheelDrag(jiggleZoneR: jiggleZoneR, maxJ: maxJ))
        .onDisappear { stopSpin() }
    }

    // MARK: - Rotating marks (under tactical gloss in export; we keep under `capOverlayAboveTactile` slot)

    private var rotatingLayer: some View {
        ZStack {
            if showIndicator {
                Circle()
                    .fill(Color.black.opacity(0.22))
                    .frame(width: diameter * 0.032, height: diameter * 0.032)
                    .offset(y: -diameter * 0.225)

                Capsule()
                    .fill(Color.black.opacity(0.10))
                    .frame(width: diameter * 0.014, height: diameter * 0.05)
                    .offset(y: -diameter * 0.30)
            }

            if isActive {
                Circle()
                    .stroke(Color.orange.opacity(0.18), lineWidth: 2)
                    .frame(width: diameter * 0.46, height: diameter * 0.46)
            }
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(rotation))
        .animation(isDragging || spinTimer != nil || isPlaying ? nil
                                                 : .interactiveSpring(response: 0.4, dampingFraction: 0.85),
                   value: rotation)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private func wheelDrag(jiggleZoneR: CGFloat, maxJ: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: diameter / 2, y: diameter / 2)
                let startVec = CGSize(
                    width: value.startLocation.x - center.x,
                    height: value.startLocation.y - center.y
                )
                let startDist = hypot(startVec.width, startVec.height)

                if dragMode == nil {
                    dragMode = startDist <= jiggleZoneR ? .jiggle : .jog
                    wasJiggleDragging = false
                    if dragMode == .jiggle {
                        stopSpin()
                        if enableHaptics {
                            hapticGrab.prepare(); hapticSoft.prepare(); hapticDetent.prepare()
                            hapticGrab.impactOccurred(intensity: 0.38)
                        }
                    }
                }

                switch dragMode {
                case .jiggle:
                    processJiggle(translation: value.translation, maxJ: maxJ)
                case .jog:
                    processJog(value: value, center: center)
                case nil:
                    break
                }
            }
            .onEnded { value in
                defer {
                    dragMode = nil
                    isDragging = false
                    dragStartAngle = nil
                    burst = 0
                    lastAngle = nil
                    lastTime = nil
                    velocitySamples.removeAll()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        wasJiggleDragging = false
                    }
                }

                guard let mode = dragMode else { return }

                if mode == .jiggle {
                    let mag = hypot(value.translation.width, value.translation.height)
                    let tapSlop: CGFloat = 6
                    let jiggleAction: CGFloat = 10
                    if mag >= jiggleAction {
                        // Inner stick — seek within the current track only.
                        if abs(value.translation.height) >= abs(value.translation.width) {
                            if value.translation.height < 0 {
                                onJiggleSeekForward()
                            } else {
                                onJiggleSeekBack()
                            }
                        } else if value.translation.width > 0 {
                            onJiggleSeekForward()
                        } else {
                            onJiggleSeekBack()
                        }
                        if enableHaptics { hapticSoft.impactOccurred(intensity: 0.55) }
                    } else if mag < tapSlop {
                        onCenterTap()
                    }
                    springJiggleHome()
                    return
                }

                let v = computeFlingVelocity()

                if burst >= snapAngle {
                    onSnapForward()
                    if enableHaptics { hapticSnap.impactOccurred() }
                } else if burst <= -snapAngle {
                    onSnapBack()
                    if enableHaptics { hapticSnap.impactOccurred() }
                }

                dragStartAngle = nil
                burst = 0

                if abs(v) > stopVelocity * 6 {
                    spinVelocity = v
                    startSpin()
                } else {
                    onScratchEnd?()
                    onScrubEnd()
                }
            }
    }

    private func processJiggle(translation: CGSize, maxJ: CGFloat) {
        wasJiggleDragging = true
        var v = CGSize(width: translation.width, height: translation.height)
        let m = hypot(v.width, v.height)
        if m > maxJ, m > 0 {
            let s = maxJ / m
            v.width *= s
            v.height *= s
            if enableHaptics {
                let now = Date()
                if now.timeIntervalSince(lastEdgeHaptic) > 0.12 {
                    lastEdgeHaptic = now
                    hapticSoft.impactOccurred(intensity: 0.52)
                }
            }
        }
        jiggleDisplay = v
    }

    private func springJiggleHome() {
        withAnimation(.spring(response: 0.44, dampingFraction: 0.72)) {
            jiggleDisplay = .zero
        }
        if enableHaptics {
            hapticSoft.prepare()
            hapticSoft.impactOccurred(intensity: 0.65)
        }
    }

    private func processJog(value: DragGesture.Value, center: CGPoint) {
        if !isDragging {
            stopSpin()
            isDragging = true
            if enableHaptics {
                hapticGrab.impactOccurred(intensity: 0.45)
                hapticDetent.prepare()
                hapticSnap.prepare()
            }
        }

        let angle = degrees(atan2(value.location.y - center.y, value.location.x - center.x))
        let now = Date()

        if dragStartAngle == nil {
            dragStartAngle = angle
            dragStartRot = rotation
            burst = 0
            lastAngle = angle
            lastTime = now
            lastDetentMark = rotation
            velocitySamples.removeAll()
            onJogBegin()
        }

        if let prev = lastAngle, let prevT = lastTime {
            let d = wrap(angle - prev)
            let dt = max(0.001, now.timeIntervalSince(prevT))
            onScratchDelta?(d, d / dt / 60.0)
        }
        lastAngle = angle
        lastTime = now

        if let start = dragStartAngle {
            let delta = wrap(angle - start)
            burst = delta
            rotation = dragStartRot + delta

            velocitySamples.append((now, rotation))
            let cutoff = now.addingTimeInterval(-0.12)
            velocitySamples.removeAll { $0.t < cutoff }

            fireDetentHapticsIfNeeded()

            onScrub(delta)
        }
    }

    // MARK: - Inertia spin

    private func startSpin() {
        stopSpin()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
            DispatchQueue.main.async { tickSpin() }
        }
        spinTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func tickSpin() {
        guard spinTimer != nil else { return }
        rotation += spinVelocity
        onScratchDelta?(spinVelocity, spinVelocity)
        fireDetentHapticsIfNeeded()
        spinVelocity *= friction
        if abs(spinVelocity) < stopVelocity {
            stopSpin()
            onScratchEnd?()
            onScrubEnd()
        }
    }

    private func stopSpin() {
        spinTimer?.invalidate()
        spinTimer = nil
        spinVelocity = 0
    }

    private func fireDetentHapticsIfNeeded() {
        let diff = rotation - lastDetentMark
        guard abs(diff) >= detentAngle else { return }
        let steps = (diff / detentAngle).rounded(.towardZero)
        lastDetentMark += steps * detentAngle
        guard enableHaptics else { return }
        let intensity = min(1.0, max(0.25, abs(spinVelocity) / 6.0 + 0.35))
        hapticDetent.impactOccurred(intensity: intensity)
    }

    private func computeFlingVelocity() -> Double {
        guard let first = velocitySamples.first,
              let last = velocitySamples.last else { return 0 }
        let dt = last.t.timeIntervalSince(first.t)
        guard dt > 0.001 else { return 0 }
        let dRot = last.r - first.r
        return dRot / dt / 60.0
    }

    private func degrees(_ radians: CGFloat) -> Double { Double(radians) * 180 / .pi }

    private func wrap(_ d: Double) -> Double {
        var x = d
        if x > 180 { x -= 360 }
        if x < -180 { x += 360 }
        return x
    }
}

extension FigmaJogWheel where CapExtras == EmptyView {
    init(
        diameter: CGFloat = FigmaTheme.jogWheelDiameter,
        rotation: Binding<Double>,
        isPlaying: Bool = false,
        isActive: Bool = false,
        innerPressed: Bool = false,
        showIndicator: Bool = true,
        enableHaptics: Bool = true,
        detentAngle: Double = 15,
        snapAngle: Double = 60,
        friction: Double = 0.94,
        stopVelocity: Double = 0.06,
        jiggleTravel: CGFloat = 0.13,
        onCenterTap: @escaping () -> Void,
        onSnapForward: @escaping () -> Void,
        onSnapBack: @escaping () -> Void,
        onJiggleSeekForward: @escaping () -> Void,
        onJiggleSeekBack: @escaping () -> Void,
        onJogBegin: @escaping () -> Void = {},
        onScrub: @escaping (Double) -> Void,
        onScrubEnd: @escaping () -> Void,
        onScratchDelta: ((Double, Double) -> Void)? = nil,
        onScratchEnd: (() -> Void)? = nil
    ) {
        self.init(
            diameter: diameter,
            rotation: rotation,
            isPlaying: isPlaying,
            isActive: isActive,
            innerPressed: innerPressed,
            showIndicator: showIndicator,
            enableHaptics: enableHaptics,
            detentAngle: detentAngle,
            snapAngle: snapAngle,
            friction: friction,
            stopVelocity: stopVelocity,
            jiggleTravel: jiggleTravel,
            onCenterTap: onCenterTap,
            onSnapForward: onSnapForward,
            onSnapBack: onSnapBack,
            onJiggleSeekForward: onJiggleSeekForward,
            onJiggleSeekBack: onJiggleSeekBack,
            onJogBegin: onJogBegin,
            onScrub: onScrub,
            onScrubEnd: onScrubEnd,
            onScratchDelta: onScratchDelta,
            onScratchEnd: onScratchEnd,
            capOverlayAboveTactile: { EmptyView() }
        )
    }
}

// MARK: - Preview

#Preview("Knob — jiggle + jog") {
    StatefulPreview()
        .padding(40)
        .background(FigmaTheme.panelGrey)
}

private struct StatefulPreview: View {
    @State private var rotation: Double = 0
    @State private var innerPressed = false
    @State private var lastEvent: String = "—"

    var body: some View {
        VStack(spacing: 16) {
            FigmaJogWheel(
                diameter: 200,
                rotation: $rotation,
                isPlaying: true,
                isActive: true,
                innerPressed: innerPressed,
                onCenterTap: {
                    innerPressed = true
                    lastEvent = "TAP centre"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { innerPressed = false }
                },
                onSnapForward: { lastEvent = "SKIP →" },
                onSnapBack: { lastEvent = "SKIP ←" },
                onJiggleSeekForward: { lastEvent = "SEEK +10s" },
                onJiggleSeekBack: { lastEvent = "SEEK −10s" },
                onScrub: { _ in },
                onScrubEnd: { },
                onScratchDelta: { _, _ in },
                onScratchEnd: { }
            )

            Text(String(format: "rot %.0f°   ·   %@", rotation, lastEvent))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.black)
        }
    }
}
