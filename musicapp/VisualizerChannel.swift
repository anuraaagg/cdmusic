import SwiftUI

/// Visualizer presets — arcade genre labels on the embedded display (`465:10827`).
enum VisualizerChannel: String, CaseIterable, Identifiable {
    case cosmicVHS = "HIP-HOP"
    case nebulaDream = "DISCO"
    case crtBloom = "TECHNO"
    case deepSpace = "DEEP"

    var id: String { rawValue }

    var displayLabel: String { rawValue }

    var jamCounterIndex: Int {
        (Self.allCases.firstIndex(of: self) ?? 0) + 1
    }

    var yFraction: CGFloat {
        switch self {
        case .cosmicVHS: 0.108
        case .nebulaDream: 0.200
        case .crtBloom: 0.292
        case .deepSpace: 0.108
        }
    }

    func next() -> VisualizerChannel {
        let all = Self.allCases
        let i = (all.firstIndex(of: self)! + 1) % all.count
        return all[i]
    }

    var metalParams: (hue: Double, bloom: Double, grain: Double, chroma: Double, saturation: Double) {
        switch self {
        case .cosmicVHS:   return (0.88, 1.0, 0.20, 0.0018, 1.18)
        case .nebulaDream: return (0.62, 0.75, 0.14, 0.0012, 1.22)
        case .crtBloom:    return (0.35, 1.15, 0.17, 0.0024, 1.26)
        case .deepSpace:   return (0.72, 0.55, 0.12, 0.0010, 1.14)
        }
    }
}
