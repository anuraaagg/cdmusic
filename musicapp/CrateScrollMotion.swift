import Combine
import QuartzCore
import SwiftUI

enum CrateScrollSpace {
    static let name = "crateCarousel"
}

// MARK: - Scroll velocity tracker

@MainActor
final class CrateScrollMotionTracker: ObservableObject {
    @Published private(set) var offsetX: CGFloat = 0
    /// Horizontal scroll speed in points / second (positive = content moving left).
    @Published private(set) var velocityX: CGFloat = 0

    private var lastOffsetX: CGFloat = 0
    private var lastSampleTime: CFTimeInterval = 0
    private var decayLink: CADisplayLink?
    private var decayTarget: DisplayLinkTarget?

    func ingest(contentOffsetX: CGFloat) {
        let now = CACurrentMediaTime()

        if lastSampleTime > 0 {
            let dt = min(0.05, now - lastSampleTime)
            if dt > 0.0001 {
                let instant = (contentOffsetX - lastOffsetX) / dt
                velocityX = velocityX * 0.5 + instant * 0.5
                startDecayIfNeeded()
            }
        }

        lastOffsetX = contentOffsetX
        lastSampleTime = now
        offsetX = contentOffsetX
    }

    /// Normalized distance from viewport centre (−1…1, 0 = centred).
    func parallaxNorm(
        index: Int,
        cellSize: CGFloat,
        gap: CGFloat,
        leadingPad: CGFloat,
        viewportWidth: CGFloat
    ) -> CGFloat {
        guard viewportWidth > 0 else { return 0 }

        let itemCenter = leadingPad + CGFloat(index) * (cellSize + gap) + cellSize * 0.5
        let visibleCenter = offsetX + viewportWidth * 0.5
        let dist = itemCenter - visibleCenter
        return dist / max(viewportWidth * 0.42, 1)
    }

    private func startDecayIfNeeded() {
        guard decayLink == nil else { return }

        let target = DisplayLinkTarget { [weak self] in
            self?.decayVelocity()
        }
        decayTarget = target
        let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.handleDisplayLink))
        link.add(to: .main, forMode: .common)
        decayLink = link
    }

    private func stopDecay() {
        decayLink?.invalidate()
        decayLink = nil
        decayTarget = nil
    }

    private func decayVelocity() {
        velocityX *= 0.90
        if abs(velocityX) < 1.5 {
            velocityX = 0
            stopDecay()
        }
    }
}

private final class DisplayLinkTarget: NSObject {
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    @objc func handleDisplayLink() {
        callback()
    }
}

// MARK: - Parallax depth between carousel discs

private struct CrateVinylParallaxModifier: ViewModifier {
    let norm: CGFloat

    func body(content: Content) -> some View {
        let clamped = max(-1.2, min(1.2, norm))
        let depth = 1 - abs(clamped) * 0.10
        let yLift = abs(clamped) * 4
        let tilt = clamped * -10

        content
            .scaleEffect(depth)
            .offset(y: yLift)
            .rotation3DEffect(
                .degrees(tilt),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.35
            )
            .zIndex(Double(100) - Double(abs(clamped)) * 20)
    }
}

extension View {
    func crateVinylParallax(norm: CGFloat) -> some View {
        modifier(CrateVinylParallaxModifier(norm: norm))
    }
}
