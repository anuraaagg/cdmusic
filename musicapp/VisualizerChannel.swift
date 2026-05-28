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
}
