import SwiftUI

// MARK: - Tapered web connectors (`396:3513`)

enum SavedCrateWebConnectorPath {

    /// Fluid web strand: smooth cubic spline spine + cosine taper (thick at rims, slender mid-span).
    static func taperedStrand(
        from start: CGPoint,
        to end: CGPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) -> Path {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length >= 2 else {
            let r: CGFloat = 2
            return Path(ellipseIn: CGRect(x: start.x - r, y: start.y - r, width: r * 2, height: r * 2))
        }

        let ux = dx / length
        let uy = dy / length
        let px = -uy
        let py = ux

        let wStart = max(4, min(startRadius * 0.26, length * 0.22))
        let wEnd = max(4, min(endRadius * 0.26, length * 0.22))
        /// Mid-span stays visibly thin (“silk”), rims stay fuller for soft attachment to discs.
        let wThinFloor = max(1.75, length * 0.018)

        let sag = min(28, length * 0.1)
        let c1 = CGPoint(
            x: start.x + ux * length * 0.38 + px * sag,
            y: start.y + uy * length * 0.38 + py * sag
        )
        let c2 = CGPoint(
            x: end.x - ux * length * 0.38 + px * sag,
            y: end.y - uy * length * 0.38 + py * sag
        )

        let stepCount = min(72, max(22, Int(length / 8)))
        var leftRail: [CGPoint] = []
        var rightRail: [CGPoint] = []
        leftRail.reserveCapacity(stepCount + 1)
        rightRail.reserveCapacity(stepCount + 1)

        func cubic(_ t: CGFloat) -> CGPoint {
            let mt = 1 - t
            let a = mt * mt * mt
            let b = 3 * mt * mt * t
            let c = 3 * mt * t * t
            let d = t * t * t
            return CGPoint(
                x: a * start.x + b * c1.x + c * c2.x + d * end.x,
                y: a * start.y + b * c1.y + c * c2.y + d * end.y
            )
        }

        func cubicTangent(_ t: CGFloat) -> CGPoint {
            let delta: CGFloat = 1 / CGFloat(max(stepCount * 4, 12))
            let t0 = max(0, min(1, t - delta))
            let t1 = max(0, min(1, t + delta))
            let p0 = cubic(t0)
            let p1 = cubic(t1)
            let txn = p1.x - p0.x
            let tyn = p1.y - p0.y
            let tn = hypot(txn, tyn)
            guard tn > 0.0001 else { return CGPoint(x: ux, y: uy) }
            return CGPoint(x: txn / tn, y: tyn / tn)
        }

        let pi = CGFloat(Double.pi)

        for i in 0...stepCount {
            let u = CGFloat(i) / CGFloat(stepCount)
            let curvePoint = cubic(u)
            let tg = cubicTangent(u)
            let nx = -tg.y
            let ny = tg.x

            let endBlend = wStart * (1 - u) + wEnd * u
            let widen = CGFloat(pow(Double(cos(pi * u)), 2))
            let half = wThinFloor + widen * max(endBlend - wThinFloor, 1)

            leftRail.append(CGPoint(x: curvePoint.x + nx * half, y: curvePoint.y + ny * half))
            rightRail.append(CGPoint(x: curvePoint.x - nx * half, y: curvePoint.y - ny * half))
        }

        var path = Path()
        guard let l0 = leftRail.first else { return path }
        path.move(to: l0)
        for p in leftRail.dropFirst() {
            path.addLine(to: p)
        }
        for p in rightRail.reversed() {
            path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }
}
