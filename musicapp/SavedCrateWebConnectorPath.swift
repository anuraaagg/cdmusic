import SwiftUI

// MARK: - Crate web strands

/// Straight chord + taper (thin waist, morphs as rim anchors move). Waist corners use a small quadratic fillet.
enum SavedCrateWebConnectorPath {

    private static func pointOnRay(from corner: CGPoint, toward target: CGPoint, distance: CGFloat) -> CGPoint {
        let ox = target.x - corner.x
        let oy = target.y - corner.y
        let len = max(0.001, hypot(ox, oy))
        return CGPoint(x: corner.x + ox / len * distance, y: corner.y + oy / len * distance)
    }

    /// Straight segment **start → end**: somewhat narrow at rims, thinnest at midpoint; waist “tip” is softly rounded (quadratic fillet).
    static func straightTaperedStrand(
        from start: CGPoint,
        to end: CGPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) -> Path {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length >= 1 else {
            var p = Path()
            let r = max(3, min(startRadius, endRadius) * 0.12)
            p.addEllipse(in: CGRect(x: start.x - r, y: start.y - r, width: r * 2, height: r * 2))
            return p
        }

        let ux = dx / length
        let uy = dy / length
        let nx = -uy
        let ny = ux

        /// Thinner attachment at discs than previous build.
        let halfWideStart = max(3.2, min(startRadius * 0.17, length * 0.12))
        let halfWideEnd = max(3.2, min(endRadius * 0.17, length * 0.12))
        let halfWideMid = max(1.15, min(halfWideStart, halfWideEnd) * 0.24)

        let mid = CGPoint(x: (start.x + end.x) * 0.5, y: (start.y + end.y) * 0.5)

        let l0 = CGPoint(x: start.x + nx * halfWideStart, y: start.y + ny * halfWideStart)
        let lm = CGPoint(x: mid.x + nx * halfWideMid, y: mid.y + ny * halfWideMid)
        let l1 = CGPoint(x: end.x + nx * halfWideEnd, y: end.y + ny * halfWideEnd)
        let r1 = CGPoint(x: end.x - nx * halfWideEnd, y: end.y - ny * halfWideEnd)
        let rm = CGPoint(x: mid.x - nx * halfWideMid, y: mid.y - ny * halfWideMid)
        let r0 = CGPoint(x: start.x - nx * halfWideStart, y: start.y - ny * halfWideStart)

        let lenL0m = hypot(lm.x - l0.x, lm.y - l0.y)
        let lenmL1 = hypot(l1.x - lm.x, l1.y - lm.y)
        let lenR1m = hypot(rm.x - r1.x, rm.y - r1.y)
        let lenmR0 = hypot(r0.x - rm.x, r0.y - rm.y)

        let waistInset = min(
            max(length * 0.052, 6.5),
            lenL0m * 0.46,
            lenmL1 * 0.46,
            min(halfWideStart, halfWideEnd) * 1.1
        )
        let waistInsetR = min(
            max(length * 0.052, 6.5),
            lenR1m * 0.46,
            lenmR0 * 0.46,
            min(halfWideStart, halfWideEnd) * 1.1
        )

        let lA = pointOnRay(from: lm, toward: l0, distance: waistInset)
        let lB = pointOnRay(from: lm, toward: l1, distance: waistInset)
        let rA = pointOnRay(from: rm, toward: r1, distance: waistInsetR)
        let rB = pointOnRay(from: rm, toward: r0, distance: waistInsetR)

        var path = Path()
        path.move(to: l0)
        path.addLine(to: lA)
        path.addQuadCurve(to: lB, control: lm)
        path.addLine(to: l1)
        path.addLine(to: r1)
        path.addLine(to: rA)
        path.addQuadCurve(to: rB, control: rm)
        path.addLine(to: r0)
        path.closeSubpath()
        return path
    }
}
