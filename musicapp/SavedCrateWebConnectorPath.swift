import SwiftUI

// MARK: - Crate web strands (Figma `396:3396`, vector `396:3513`)

/// Paths for edges on the Saved Crate web canvas. Stroked Bézier spine = uniform thickness (per Figma spec), morphing as anchors move when discs drag.
enum SavedCrateWebConnectorPath {

    /// Cubic spine from rim anchor → rim anchor. Stroke with fixed `lineWidth` + `.round` caps/joins everywhere for even thickness (no midpoint taper).
    static func uniformStrandSpine(from start: CGPoint, to end: CGPoint) -> Path {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length >= 2 else {
            var p = Path()
            let r: CGFloat = max(4, SavedCrateWebGraph.uniformWebStrandLineWidth * 0.5)
            p.addEllipse(in: CGRect(x: start.x - r, y: start.y - r, width: r * 2, height: r * 2))
            return p
        }

        let ux = dx / length
        let uy = dy / length
        let px = -uy
        let py = ux

        let sag = min(28, length * 0.1)
        let c1 = CGPoint(
            x: start.x + ux * length * 0.38 + px * sag,
            y: start.y + uy * length * 0.38 + py * sag
        )
        let c2 = CGPoint(
            x: end.x - ux * length * 0.38 + px * sag,
            y: end.y - uy * length * 0.38 + py * sag
        )

        var path = Path()
        path.move(to: start)
        path.addCurve(to: end, control1: c1, control2: c2)
        return path
    }
}
