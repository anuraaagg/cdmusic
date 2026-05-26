#if DEBUG
import CoreGraphics
import Foundation

enum SavedCrateWebGraphTests {
    private static func degreeCount(edges: [SavedCrateWebEdge]) -> [UUID: Int] {
        var m: [UUID: Int] = [:]
        for e in edges {
            m[e.a, default: 0] += 1
            m[e.b, default: 0] += 1
        }
        return m
    }

    static func run() -> [String] {
        var failures: [String] = []

        let sharedArtist = SavedMoment(
            trackPersistentID: 1,
            title: "A",
            artist: "NEON DRIFT",
            genre: "ELECTRONIC",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )
        let sameArtist = SavedMoment(
            trackPersistentID: 2,
            title: "B",
            artist: "neon drift",
            genre: "SYNTH",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )
        let sameGenre = SavedMoment(
            trackPersistentID: 3,
            title: "C",
            artist: "OTHER",
            genre: "SYNTH",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )
        let unrelated = SavedMoment(
            trackPersistentID: 4,
            title: "D",
            artist: "UNRELATED",
            genre: "JAZZ",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )

        if !SavedCrateWebGraph.shouldConnect(sharedArtist, sameArtist) {
            failures.append("expected artist match edge")
        }
        if !SavedCrateWebGraph.shouldConnect(sameArtist, sameGenre) {
            failures.append("expected genre match edge")
        }
        if SavedCrateWebGraph.shouldConnect(sharedArtist, unrelated) {
            failures.append("unexpected edge for unrelated moments")
        }

        let edges = SavedCrateWebGraph.buildEdges(from: [sharedArtist, sameArtist, sameGenre, unrelated])
        if edges.count != 1 {
            failures.append("expected greedy max-degree-1 to yield 1 edge got \(edges.count)")
        }
        let deg = SavedCrateWebGraphTests.degreeCount(edges: edges)
        for (_, d) in deg where d > 1 {
            failures.append("unexpected degree \(d) (>1) with max one strand per disc")
        }

        let layout = SavedCrateWebGraph.build(
            moments: [sharedArtist, sameArtist, sameGenre],
            viewport: CGSize(width: 390, height: 520)
        )
        if layout.nodes.count != 3 {
            failures.append("layout node count expected 3 got \(layout.nodes.count)")
        }
        if layout.canvasSize.width < 390 {
            failures.append("canvas width too small")
        }

        /// Unrelated metadata → no `buildEdges` pairs, but `build` adds proximity links so nothing floats alone.
        let lone1 = SavedMoment(
            trackPersistentID: 200,
            title: "L1",
            artist: "ZEBRA ONLY",
            genre: "QQ",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )
        let lone2 = SavedMoment(
            trackPersistentID: 201,
            title: "L2",
            artist: "YAK ONLY",
            genre: "RR",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )
        let lone3 = SavedMoment(
            trackPersistentID: 202,
            title: "L3",
            artist: "XRAY ONLY",
            genre: "SS",
            skin: .normal,
            accentHex: nil,
            artwork: nil
        )
        if !SavedCrateWebGraph.buildEdges(from: [lone1, lone2, lone3]).isEmpty {
            failures.append("expected zero metadata edges for three unrelated moments")
        }
        let loneLayout = SavedCrateWebGraph.build(
            moments: [lone1, lone2, lone3],
            viewport: CGSize(width: 390, height: 520)
        )
        let loneDeg = SavedCrateWebGraphTests.degreeCount(edges: loneLayout.edges)
        for n in loneLayout.nodes where loneDeg[n.id, default: 0] < 1 {
            failures.append("proximity bridge: node \(n.id) has no strand")
        }

        #if DEBUG
        let demoEdges = SavedCrateWebGraph.buildEdges(from: SavedCrateDemoData.moments)
        /// With one connection per CD, at most floor(n/2) edges.
        let maxDemo = SavedCrateDemoData.moments.count / 2
        if demoEdges.count > maxDemo {
            failures.append("demo vinyls: expected at most \(maxDemo) edges with max degree 1 got \(demoEdges.count)")
        }
        if SavedCrateDemoData.moments.count != 8 {
            failures.append("demo vinyl count expected 8")
        }
        #endif

        return failures
    }
}
#endif
