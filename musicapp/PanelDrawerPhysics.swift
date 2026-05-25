import SwiftUI

// MARK: - Panel ↔ crate drawer physics

/// Rubber-band overscroll and flick settle for the control panel drawer.
enum PanelDrawerPhysics {

    /// Max fraction overshoot when pulling past fully open (crate revealed).
    static let openOvershootLimit: CGFloat = 0.11
    /// Max overshoot when pulling the panel back up past fully closed.
    static let closeOvershootLimit: CGFloat = 0.07

    /// Past this fraction (0 = open, 1 = closed), release commits to the nearer endpoint via spring.
    static let commitThreshold: CGFloat = 0.5

    /// Maps raw drag fraction (can exceed 0…1) to a resisted overscroll value.
    static func rubberBandedFraction(_ raw: CGFloat) -> CGFloat {
        if raw >= 0, raw <= 1 { return raw }
        if raw < 0 {
            let overshoot = -raw
            return -rubberOffset(overshoot, limit: openOvershootLimit)
        }
        let overshoot = raw - 1
        return 1 + rubberOffset(overshoot, limit: closeOvershootLimit)
    }

    /// Drag follows finger 1:1 inside 0…1; rubber band only past the endpoints.
    static func resistedDragFraction(anchor: CGFloat, delta: CGFloat) -> CGFloat {
        rubberBandedFraction(anchor - delta)
    }

    /// Settle target after drag end; `flickPixels` is predicted − actual translation (pt, + = downward).
    static func settleTarget(
        revealFraction: CGFloat,
        flickPixels: CGFloat,
        maxSlide: CGFloat
    ) -> (target: CGFloat, initialVelocity: CGFloat) {
        guard maxSlide > 0 else {
            return (revealFraction > commitThreshold ? 1 : 0, 0)
        }

        let flickVelocity = -flickPixels / maxSlide

        let target: CGFloat
        if abs(flickVelocity) > 0.72 {
            target = flickVelocity > 0 ? 0 : 1
        } else if flickPixels > 95 {
            target = 0
        } else if flickPixels < -95 {
            target = 1
        } else {
            // Past halfway — spring finishes the motion; no need to drag to the end.
            target = revealFraction > commitThreshold ? 1 : 0
        }

        let displacement = target - revealFraction
        let initialVelocity = min(14, max(-14, displacement * 5.2 + flickVelocity * 2.4))
        return (target, initialVelocity)
    }

    static func settleAnimation(initialVelocity: CGFloat) -> Animation {
        .interpolatingSpring(stiffness: 298, damping: 23.5, initialVelocity: initialVelocity)
    }

    static func panelSlideAnimation(initialVelocity: CGFloat = 0) -> Animation {
        if abs(initialVelocity) > 0.05 {
            return .interpolatingSpring(stiffness: 298, damping: 23.5, initialVelocity: initialVelocity)
        }
        return .spring(response: 0.44, dampingFraction: 0.78)
    }

    private static func rubberOffset(_ overshoot: CGFloat, limit: CGFloat) -> CGFloat {
        guard overshoot > 0, limit > 0 else { return 0 }
        return limit * (1 - exp(-overshoot * 5.4))
    }
}
