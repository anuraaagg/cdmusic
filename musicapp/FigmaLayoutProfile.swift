import SwiftUI

enum FigmaDeviceTier: Equatable {
    case small
    case compact
    case large

    static func resolve(width: CGFloat, height: CGFloat) -> FigmaDeviceTier {
        if width <= 375 || height < 700 { return .small }
        // Figma reference width (402 pt) and Pro-class heights get full 24 pt hero tail.
        if width >= 402 && height >= 740 { return .large }
        return .compact
    }
}

enum FigmaLayoutProfile {
    case compact
    case standard

    static func resolve(viewportWidth: CGFloat, viewportHeight: CGFloat) -> FigmaLayoutProfile {
        let tier = FigmaDeviceTier.resolve(width: viewportWidth, height: viewportHeight)
        switch tier {
        case .small, .compact: return .compact
        case .large: return .standard
        }
    }
}
