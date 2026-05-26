import CoreGraphics
import Foundation
import UIKit

// MARK: - Saved crate CD web graph (`396:3505`)

struct SavedCrateWebEdge: Identifiable, Equatable {
    let id: String
    let a: UUID
    let b: UUID
}

struct SavedCrateWebNode: Identifiable, Equatable {
    let moment: SavedMoment
    let diameter: CGFloat
    var center: CGPoint

    var id: UUID { moment.id }
    var radius: CGFloat { diameter / 2 }
}

struct SavedCrateWebLayout: Equatable {
    var nodes: [SavedCrateWebNode]
    var edges: [SavedCrateWebEdge]
    /// Full pannable canvas — larger than viewport for infinite feel.
    var canvasSize: CGSize
    /// Graph centroid in canvas space (for initial scroll centering).
    var graphCenter: CGPoint
}

enum SavedCrateWebGraph {

    static let diameterTiers: [CGFloat] = [120, 150, 153, 165, 223]
    /// Shrinks discs on canvas for overview; pinch-zoom in view brings detail without crowding edges.
    static let webCanvasNodeDiameterScale: CGFloat = 0.48
    /// Extra canvas margin beyond viewport — supports panning in all directions.
    static let canvasMargin: CGFloat = 520
    /// Extra scrollable slack below laid-out discs so idle grey stays visible above the floating share bar (`396:3505`).
    static let webCanvasExtraBottomSlack: CGFloat = 168
    /// Initial graph centroid nudged up in canvas coords — reserves “empty” field below until the user pans/drags.
    static let webCanvasInitialVerticalBias: CGFloat = 72

    /// Nominal tier → rendered diameter (floored so tap targets remain usable).
    static func scaledLayoutDiameter(_ nominal: CGFloat) -> CGFloat {
        max(54, nominal * webCanvasNodeDiameterScale)
    }

    /// geometryReader can report CGSize.zero briefly; inverted clamp bounds collapsed every disc to one point.
    private static func layoutViewport(_ viewport: CGSize) -> CGSize {
        CGSize(width: max(viewport.width, 320), height: max(viewport.height, 480))
    }

    /// Figma `396:3512` node centers in 628.5 × 625.5 design space (hub last = largest slot).
    private static let figmaSeedCenters: [CGPoint] = [
        CGPoint(x: 82.5, y: 82.5),
        CGPoint(x: 443.63, y: 90.75),
        CGPoint(x: 271.5, y: 221.25),
        CGPoint(x: 151.88, y: 518.63),
        CGPoint(x: 544.88, y: 248.63),
        CGPoint(x: 517.5, y: 552),
        CGPoint(x: 92.25, y: 296.25),
        CGPoint(x: 314.65, y: 407.63),
    ]

    private static let figmaSeedDiameters: [CGFloat] = [165, 153, 120, 120, 165, 165, 150, 223]

    static func build(moments: [SavedMoment], viewport: CGSize) -> SavedCrateWebLayout {
        let emptyCanvas = infiniteCanvasSize(viewport: viewport, graphBounds: .zero)
        guard !moments.isEmpty else {
            return SavedCrateWebLayout(
                nodes: [],
                edges: [],
                canvasSize: emptyCanvas,
                graphCenter: CGPoint(x: emptyCanvas.width * 0.5, y: emptyCanvas.height * 0.5)
            )
        }

        let baseEdges = buildEdges(from: moments)
        let degreeByNodeId = degreeMap(for: moments, edges: baseEdges)
        let ranked = moments.sorted { lhs, rhs in
            let dl = degreeByNodeId[lhs.id, default: 0]
            let dr = degreeByNodeId[rhs.id, default: 0]
            if dl != dr { return dl > dr }
            return lhs.createdAt > rhs.createdAt
        }

        let padding: CGFloat = 36
        let layoutVp = layoutViewport(viewport)
        let design = CGSize(width: 628.5, height: 625.5)
        let scale = min(
            (layoutVp.width - padding * 2) / design.width,
            (layoutVp.height - padding * 2) / design.height
        )

        var nodes: [SavedCrateWebNode] = []
        if ranked.count <= figmaSeedCenters.count {
            let graphW = design.width * scale
            let graphH = design.height * scale
            let localOffsetX = (layoutVp.width - graphW) * 0.5
            let localOffsetY = (layoutVp.height - graphH) * 0.5
            for (index, moment) in ranked.enumerated() {
                let seed = figmaSeedCenters[index]
                let nominal = figmaSeedDiameters[index] * scale
                let d = scaledLayoutDiameter(nominal)
                let center = CGPoint(
                    x: localOffsetX + seed.x * scale,
                    y: localOffsetY + seed.y * scale
                )
                nodes.append(SavedCrateWebNode(moment: moment, diameter: d, center: center))
            }
        } else {
            nodes = discSpreadLayout(
                ranked: ranked,
                edges: baseEdges,
                viewport: layoutVp
            )
        }

        let bounds = graphBounds(for: nodes)
        let canvasSize = infiniteCanvasSize(viewport: viewport, graphBounds: bounds)
        let shift = canvasShift(canvasSize: canvasSize, graphBounds: bounds)
        let shifted = nodes.map { node in
            SavedCrateWebNode(
                moment: node.moment,
                diameter: node.diameter,
                center: CGPoint(x: node.center.x + shift.x, y: node.center.y + shift.y)
            )
        }
        let center = graphCentroid(of: shifted)
        let edges = proximityBridgeEdges(nodes: shifted, baseEdges: baseEdges)

        return SavedCrateWebLayout(
            nodes: shifted,
            edges: edges,
            canvasSize: canvasSize,
            graphCenter: center
        )
    }

    private static func graphBounds(for nodes: [SavedCrateWebNode]) -> CGRect {
        guard let first = nodes.first else { return .zero }
        var rect = CGRect(
            x: first.center.x - first.radius,
            y: first.center.y - first.radius,
            width: first.diameter,
            height: first.diameter
        )
        for node in nodes.dropFirst() {
            let r = CGRect(
                x: node.center.x - node.radius,
                y: node.center.y - node.radius,
                width: node.diameter,
                height: node.diameter
            )
            rect = rect.union(r)
        }
        return rect
    }

    private static func graphCentroid(of nodes: [SavedCrateWebNode]) -> CGPoint {
        guard !nodes.isEmpty else { return .zero }
        let sx = nodes.reduce(0) { $0 + $1.center.x }
        let sy = nodes.reduce(0) { $0 + $1.center.y }
        let n = CGFloat(nodes.count)
        return CGPoint(x: sx / n, y: sy / n)
    }

    private static func infiniteCanvasSize(viewport: CGSize, graphBounds: CGRect) -> CGSize {
        let minW = max(viewport.width * 2.4, graphBounds.width + canvasMargin * 2)
        let minH = max(
            viewport.height * 2.4,
            graphBounds.height + canvasMargin * 2 + webCanvasExtraBottomSlack
        )
        return CGSize(width: minW, height: minH)
    }

    /// Place graph in the middle of the infinite canvas.
    private static func canvasShift(canvasSize: CGSize, graphBounds: CGRect) -> CGPoint {
        let targetCenter = CGPoint(
            x: canvasSize.width * 0.5,
            y: canvasSize.height * 0.5 - webCanvasInitialVerticalBias
        )
        let graphCenter = CGPoint(x: graphBounds.midX, y: graphBounds.midY)
        return CGPoint(x: targetCenter.x - graphCenter.x, y: targetCenter.y - graphCenter.y)
    }

    /// Point on circle edge aimed at another node — keeps connector lines off disc artwork.
    static func edgePoint(on center: CGPoint, toward other: CGPoint, radius: CGFloat) -> CGPoint {
        let dx = other.x - center.x
        let dy = other.y - center.y
        let dist = max(0.001, hypot(dx, dy))
        return CGPoint(x: center.x + dx / dist * radius, y: center.y + dy / dist * radius)
    }

    // MARK: - Edges (metadata: at most one strand per CD) + proximity bridges

    /// Ensures every disc has at least one connector: isolates (after `buildEdges`) link to the geometrically nearest peer.
    /// The neighbor may gain a second strand; metadata-greedy pairing still caps artist/genre edges at one per disc.
    private static func proximityBridgeEdges(nodes: [SavedCrateWebNode], baseEdges: [SavedCrateWebEdge]) -> [SavedCrateWebEdge] {
        guard nodes.count > 1 else { return baseEdges }

        var edges = baseEdges
        var pairedKeys = Set(edges.map { pairKey($0.a, $0.b) })
        let ids = nodes.map(\.id)
        var degrees = degreeMap(forNodeIds: ids, edges: edges)

        let isolates = nodes
            .filter { degrees[$0.id, default: 0] == 0 }
            .sorted { $0.id.uuidString < $1.id.uuidString }

        for o in isolates {
            var best: SavedCrateWebNode?
            var bestDist = CGFloat.infinity
            for n in nodes where n.id != o.id {
                let dx = n.center.x - o.center.x
                let dy = n.center.y - o.center.y
                let d = hypot(dx, dy)
                if d < bestDist - 1e-4 {
                    bestDist = d
                    best = n
                } else if abs(d - bestDist) <= 1e-4 {
                    guard let previous = best else {
                        best = n
                        continue
                    }
                    if n.id.uuidString < previous.id.uuidString {
                        best = n
                    }
                }
            }
            guard let nearest = best else { continue }
            let key = pairKey(o.id, nearest.id)
            guard !pairedKeys.contains(key) else { continue }
            edges.append(SavedCrateWebEdge(id: key, a: o.id, b: nearest.id))
            pairedKeys.insert(key)
            degrees[o.id, default: 0] += 1
            degrees[nearest.id, default: 0] += 1
        }

        return edges
    }

    static func buildEdges(from moments: [SavedMoment]) -> [SavedCrateWebEdge] {
        let count = moments.count
        guard count > 1 else { return [] }

        var degrees = Dictionary(uniqueKeysWithValues: moments.map { ($0.id, 0) })
        struct Candidate {
            let a: SavedMoment
            let b: SavedMoment
            let score: Int
        }

        var candidates: [Candidate] = []
        for i in 0..<(count - 1) {
            for j in (i + 1)..<count {
                let a = moments[i]
                let b = moments[j]
                guard shouldConnect(a, b) else { continue }
                var score = 0
                let ar = normalizedTag(a.artist)
                let br = normalizedTag(b.artist)
                if !ar.isEmpty, ar == br { score += 10_000 }
                let ga = normalizedTag(a.genre)
                let gb = normalizedTag(b.genre)
                if !ga.isEmpty, ga == gb { score += 1_000 }
                candidates.append(Candidate(a: a, b: b, score: score))
            }
        }

        candidates.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            return pairKey($0.a.id, $0.b.id) < pairKey($1.a.id, $1.b.id)
        }

        var edges: [SavedCrateWebEdge] = []
        for c in candidates {
            guard degrees[c.a.id, default: 0] < 1, degrees[c.b.id, default: 0] < 1 else { continue }
            let key = SavedCrateWebGraph.pairKey(c.a.id, c.b.id)
            edges.append(SavedCrateWebEdge(id: key, a: c.a.id, b: c.b.id))
            degrees[c.a.id, default: 0] += 1
            degrees[c.b.id, default: 0] += 1
        }

        return edges
    }

    /// Grow (never shrink) the scroll canvas once discs are dragged to new coordinates.
    static func layoutExpandingCanvas(
        nodes: [SavedCrateWebNode],
        edges: [SavedCrateWebEdge],
        viewport: CGSize,
        floorCanvas: CGSize?
    ) -> SavedCrateWebLayout {
        let bounds = graphBounds(for: nodes)
        let computed = infiniteCanvasSize(viewport: viewport, graphBounds: bounds)
        let w = max(floorCanvas?.width ?? 0, computed.width)
        let h = max(floorCanvas?.height ?? 0, computed.height)
        return SavedCrateWebLayout(
            nodes: nodes,
            edges: edges,
            canvasSize: CGSize(width: w, height: h),
            graphCenter: graphCentroid(of: nodes)
        )
    }

    #if DEBUG
    /// Deterministic fillers so panning/stretching strands can be tried without dozens of saves.
    static func stressPreviewMoments(targetTotal: Int, existingCount: Int, templateArtwork: UIImage?) -> [SavedMoment] {
        let needed = max(0, targetTotal - existingCount)
        guard needed > 0 else { return [] }
        return (0..<needed).map { idx in
            let pairBucket = idx / 2 // two nodes share artist → eligible for at most one shared edge between them after greedy cap
            return SavedMoment(
                trackPersistentID: nil,
                title: "Canvas sample \(idx + 1)",
                artist: "WEB GROUP \(pairBucket)",
                genre: idx.isMultiple(of: 2) ? "POPWEB" : "ROCKWEB",
                skin: .normal,
                accentHex: nil,
                artwork: templateArtwork
            )
        }
    }
    #endif

    static func shouldConnect(_ a: SavedMoment, _ b: SavedMoment) -> Bool {
        let artistA = normalizedTag(a.artist)
        let artistB = normalizedTag(b.artist)
        if !artistA.isEmpty, artistA == artistB { return true }

        let genreA = normalizedTag(a.genre)
        let genreB = normalizedTag(b.genre)
        if !genreA.isEmpty, genreA == genreB { return true }

        return false
    }

    static func normalizedTag(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func pairKey(_ a: UUID, _ b: UUID) -> String {
        a.uuidString < b.uuidString ? "\(a.uuidString)|\(b.uuidString)" : "\(b.uuidString)|\(a.uuidString)"
    }

    private static func degreeMap(for moments: [SavedMoment], edges: [SavedCrateWebEdge]) -> [UUID: Int] {
        degreeMap(forNodeIds: moments.map(\.id), edges: edges)
    }

    private static func degreeMap(forNodeIds ids: [UUID], edges: [SavedCrateWebEdge]) -> [UUID: Int] {
        var map = Dictionary(uniqueKeysWithValues: ids.map { ($0, 0) })
        for edge in edges {
            map[edge.a, default: 0] += 1
            map[edge.b, default: 0] += 1
        }
        return map
    }

    // MARK: - Spread layout (> 8 nodes)

    /// Phyllotaxis seed + pairwise separation + short edge springs. Avoids collapsing force sim and bad clamps when viewport is tiny.
    private static func discSpreadLayout(
        ranked: [SavedMoment],
        edges: [SavedCrateWebEdge],
        viewport: CGSize
    ) -> [SavedCrateWebNode] {
        let count = ranked.count
        guard count > 0 else { return [] }

        let cx = viewport.width * 0.5
        let cy = viewport.height * 0.5
        let diameters: [CGFloat] = ranked.enumerated().map {
            scaledLayoutDiameter(diameterForRank($0.offset, count: count))
        }

        /// Golden-angle spiral — deterministic, generous spacing for many small discs so the canvas stays legible zoomed-out.
        let golden = Double.pi * (3.0 - sqrt(5.0))
        let avgR = diameters.reduce(0) { $0 + $1 * 0.5 } / CGFloat(max(count, 1))
        let radialStep = max(
            avgR * 2.92,
            maxDiameter(diameters) * 0.64,
            118
        )

        var positions: [UUID: CGPoint] = [:]
        for (i, moment) in ranked.enumerated() {
            let t = Double(i)
            let r = radialStep * sqrt(t + 0.35)
            let theta = t * golden
            positions[moment.id] = CGPoint(
                x: cx + CGFloat(r * cos(theta)),
                y: cy + CGFloat(r * sin(theta))
            )
        }

        let ids = ranked.map(\.id)
        settleDiscOverlaps(ids: ids, ranked: ranked, diameters: diameters, positions: &positions, iterations: 72)

        let edgePairs = edges.map { ($0.a, $0.b) }
        applyEdgeSprings(ids: ids, ranked: ranked, diameters: diameters, edgePairs: edgePairs, positions: &positions, steps: 18)

        settleDiscOverlaps(ids: ids, ranked: ranked, diameters: diameters, positions: &positions, iterations: 32)

        return ranked.enumerated().map { index, moment in
            SavedCrateWebNode(
                moment: moment,
                diameter: diameters[index],
                center: positions[moment.id, default: CGPoint(x: cx, y: cy)]
            )
        }
    }

    private static func maxDiameter(_ diameters: [CGFloat]) -> CGFloat {
        diameters.max() ?? 160
    }

    /// Push overlapping discs apart; tiny deterministic nudge when centers coincide.
    private static func settleDiscOverlaps(
        ids: [UUID],
        ranked: [SavedMoment],
        diameters: [CGFloat],
        positions: inout [UUID: CGPoint],
        iterations: Int
    ) {
        let count = ranked.count
        guard count > 1 else { return }
        let pairPad: CGFloat = 28

        for _ in 0..<iterations {
            for i in 0..<(count - 1) {
                for j in (i + 1)..<count {
                    let idA = ids[i]
                    let idB = ids[j]
                    guard var pa = positions[idA], var pb = positions[idB] else { continue }
                    let ra = diameters[i] * 0.5
                    let rb = diameters[j] * 0.5
                    var dx = pa.x - pb.x
                    var dy = pa.y - pb.y
                    var dist = hypot(dx, dy)
                    let minSep = ra + rb + pairPad

                    if dist < 1 {
                        dx = CGFloat((i & 7) + 1) * 1.13
                        dy = CGFloat((j & 5) + 1) * 0.91
                        dist = hypot(dx, dy)
                    }

                    if dist >= minSep { continue }

                    let push = (minSep - dist) * 0.52
                    let nx = dx / dist
                    let ny = dy / dist
                    pa.x += nx * push
                    pa.y += ny * push
                    pb.x -= nx * push
                    pb.y -= ny * push
                    positions[idA] = pa
                    positions[idB] = pb
                }
            }
        }
    }

    /// Keep paired discs at a readable distance without collapsing the whole graph.
    private static func applyEdgeSprings(
        ids _: [UUID],
        ranked: [SavedMoment],
        diameters: [CGFloat],
        edgePairs: [(UUID, UUID)],
        positions: inout [UUID: CGPoint],
        steps: Int
    ) {
        let idToIndex = Dictionary(uniqueKeysWithValues: ranked.enumerated().map { ($0.element.id, $0.offset) })

        for _ in 0..<steps {
            var delta: [UUID: CGPoint] = [:]
            for (a, b) in edgePairs {
                guard let ia = idToIndex[a], let ib = idToIndex[b] else { continue }
                guard let pa = positions[a], let pb = positions[b] else { continue }
                let ra = diameters[ia] * 0.5
                let rb = diameters[ib] * 0.5
                var dx = pb.x - pa.x
                var dy = pb.y - pa.y
                let dist = max(0.5, hypot(dx, dy))
                let rest = ra + rb + 220
                let k: CGFloat = 0.11
                let f = (dist - rest) * k
                dx /= dist
                dy /= dist
                delta[a, default: .zero].x += dx * f
                delta[a, default: .zero].y += dy * f
                delta[b, default: .zero].x -= dx * f
                delta[b, default: .zero].y -= dy * f
            }
            for m in ranked {
                guard var p = positions[m.id] else { continue }
                let d = delta[m.id, default: .zero]
                p.x += d.x
                p.y += d.y
                positions[m.id] = p
            }
        }
    }

    private static func diameterForRank(_ rank: Int, count: Int) -> CGFloat {
        let tiers = diameterTiers
        let tierIndex = min(rank, tiers.count - 1)
        let base = tiers[tierIndex]
        if count <= tiers.count { return base }
        return max(96, base - CGFloat(rank) * 4)
    }
}
