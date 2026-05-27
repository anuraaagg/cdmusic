import SwiftUI
import UIKit

/// Static onboarding carousel cards — drop PNGs into `onboarding_s1` … `onboarding_s6` in Assets.
enum OnboardingCardPreviews {
    static func view(for screen: Int) -> some View {
        OnboardingCardChrome {
            Image(assetName(for: screen))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(accessibilityLabel(for: screen))
        }
    }

    /// Bundled name; falls back to existing Figma assets until custom art is added.
    static func assetName(for screen: Int) -> String {
        let primary = FigmaImage.onboardingScreen(screen)
        if UIImage(named: primary) != nil { return primary }
        return fallbackAssetNames[screen] ?? FigmaImage.cdCoverArt
    }

    private static let fallbackAssetNames: [Int: String] = [
        1: FigmaImage.cdCoverArt,
        2: FigmaImage.cdDisc,
        3: FigmaImage.dialA2,
        4: FigmaImage.vinylSleeve(0),
        5: FigmaImage.vinylSleeve(2),
        6: FigmaImage.vinylSleeve(4),
    ]

    private static func accessibilityLabel(for screen: Int) -> String {
        switch screen {
        case 1: return "Player overview"
        case 2: return "CD case open"
        case 3: return "Music library"
        case 4: return "Crate drawer"
        case 5: return "Vinyl carousel"
        case 6: return "Playback controls"
        default: return "Onboarding preview"
        }
    }
}
