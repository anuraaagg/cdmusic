import SwiftUI

// MARK: - FigmaCDHeroView
//
// Top section — Figma `305:3028` + CD jewel case `305:2722`.
//
//   48 pt safe area + 8 pt inset (applied by host)
//   + 340 × 340 case slot (`305:2722`)
//   + 8 pt gap
//   + 362 × 38 meta strip
//
// FIXED-SIZE: CD and strip never scale with screen width.

struct FigmaCDHeroView: View {
    @ObservedObject var vm: MusicPlayerViewModel
    var spacing: FigmaResponsiveSpacing = .init(tightness: 1, scale: 1, tier: .large)

    var body: some View {
        VStack(spacing: FigmaTheme.heroMetaGap) {
            FigmaCDJewelCase(
                cdAngle: vm.cdAngle,
                discArtwork: vm.heroDiscArtwork,
                discPlaceholder: vm.heroDiscPlaceholder
            )

            FigmaHeroMetaStrip(
                songTitle: vm.heroTrackTitle,
                timeText: vm.heroTimeString,
                genre: vm.heroGenre,
                onAsteriskTap: {
                    vm.impact(.light)
                    vm.showLibrary = false
                    vm.showSettings = true
                }
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - FigmaCDJewelCase
//
// Disc + case art + spine are one fused layer in a shared 340 pt slot.
// Both images scale together — no separate Figma offsets (assets are pre-aligned).

struct FigmaCDJewelCase: View {
    var cdAngle: Double
    var discArtwork: UIImage?
    var discPlaceholder: UIImage?

    private static let side = FigmaTheme.heroCDSize
    private static let cd = FigmaTheme.CD3052722.self

    var body: some View {
        ZStack {
            discLayer
                .rotationEffect(.degrees(cdAngle))

            Image(FigmaImage.cdCoverArt)
                .resizable()
                .scaledToFit()
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            Image(FigmaImage.cdCaseSpine)
                .resizable()
                .scaledToFit()
                .frame(width: Self.cd.spineWidth, height: Self.cd.spineHeight)
                .offset(x: Self.cd.spineOffsetX, y: Self.cd.spineOffsetY)
                .allowsHitTesting(false)
        }
        .frame(width: Self.side, height: Self.side)
    }

    private var discLayer: some View {
        Group {
            if let ui = discArtwork {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else if let placeholder = discPlaceholder {
                Image(uiImage: placeholder)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(FigmaImage.cdDisc)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: Self.cd.discWidth, height: Self.cd.discHeight)
        .clipped()
        .mask(
            Image(FigmaImage.cdDisc)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: Self.cd.discWidth, height: Self.cd.discHeight)
        )
    }
}

// MARK: - Top-half geometry

enum FigmaTopHalf {
    /// Fixed top safe-area inset from the physical screen edge (overrides system).
    static let heroSafeAreaTop: CGFloat = 48
    /// Extra inset below the safe area — Figma `305:3026`.
    static let maxTopInset: CGFloat = 8
    /// CD + gap + meta strip — tight content, no decorative tail.
    static var contentStackHeight: CGFloat {
        let stripH = max(FigmaTheme.heroMetaStripH, FigmaTheme.minTouchTarget)
        return FigmaTheme.heroCDSize + FigmaTheme.heroMetaGap + stripH
    }
    static let nativeWidth: CGFloat = 402

    static let topInset: CGFloat = heroSafeAreaTop + maxTopInset
    static let contentHeight: CGFloat = topInset + contentStackHeight
}

#Preview("CD Hero — 305:2722") {
    FigmaCDHeroView(vm: MusicPlayerViewModel())
        .frame(width: 402, height: FigmaTopHalf.contentStackHeight)
        .background(Color.white)
}

#Preview("CD Hero — compact 390") {
    FigmaCDHeroView(vm: MusicPlayerViewModel())
        .frame(width: 390, height: FigmaTopHalf.contentStackHeight)
        .background(Color.white)
}

#Preview("Jewel case only") {
    FigmaCDJewelCase(cdAngle: 0, discArtwork: nil, discPlaceholder: nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
}
