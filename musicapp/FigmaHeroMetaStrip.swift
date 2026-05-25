import SwiftUI

// MARK: - FigmaHeroMetaStrip
//
// Faithful re-implementation of the segmented metadata strip below the CD
// jewel case in Figma `305:3037` / `305:3119` (file: SuMsVkITTi0ZVnpJGHC5U7).
//
// Native dimensions (Figma):
//
//      ┌────┬─────────────────────────┬─────────┬─────────────────┐
//      │ ✱  │ SONG NAME XXXXXXXXXXXX… │  22:00  │ GENRE NAME      │
//      └────┴─────────────────────────┴─────────┴─────────────────┘
//        38           180                 51             93
//                              362 pt total, 38 pt tall
//
// FIXED-SIZE CONTRACT (per the user's "the bottom info bar always fixed"
// requirement): every cell is rendered at its native Figma width and the
// strip itself is a fixed 362 × 38 unit. Wider screens get more *outside*
// margin around the strip — they do NOT stretch the cells. The host
// (`FigmaCDHeroView`) centers the strip horizontally in whatever width is
// available.
//
//   • Cells share a 1 pt hairline (`#222220`, matches `FigmaTheme.hairlineBorder`).
//     Implementation uses ONE outer rectangle stroke + three 1 pt dividers
//     between cells — never two strokes meeting (which would render at 2 pt).
//   • All text uses **Helvetica 12 pt** with **-0.96 pt tracking** per Figma.
//     This matters: the time cell is a fixed 51 pt and "22:00" only fits at
//     Helvetica metrics (SF Pro / system default at 12pt is wider).
//   • Cell 2 (song name): `lineLimit(1)` + `truncationMode(.tail)`. The user's
//     spec says "truncate if size is big" — no minimum-scale-factor, the title
//     keeps its 12 pt size and falls off with an ellipsis.
//   • Cell 3 (time): fixed 51 pt; rendered with Helvetica so "22:00" / "0:00"
//     stay un-truncated.
//   • Cell 4 (genre): fixed 93 pt — matches the rightmost Figma cell rather
//     than flexing with screen width. Long genres tail-truncate.
//   • Asterisk icon (Figma 305:3121 / `figma_asterisk.svg`): the source SVG
//     uses Gaussian-blur + displacement-map + turbulence filters that iOS
//     image rendering can't reproduce, so the asterisk is drawn natively as
//     a stack of 4 rotated red capsules (covers 8 rays via rounded ends).
//

/// 4-cell hero metadata strip (asterisk · song name · time · genre).
///
/// The strip renders at a fixed 362 × 38 pt regardless of screen size —
/// only the *outside* horizontal margins flex (handled by the parent
/// `.frame(maxWidth: .infinity)`).
struct FigmaHeroMetaStrip: View {
    let songTitle: String
    let timeText: String
    let genre: String
    var onAsteriskTap: () -> Void = {}

    /// Native strip height (Figma 305:3037).
    static let nativeHeight: CGFloat = 38
    /// Native strip width — sum of cells (38 + 180 + 51 + 93).
    static let nativeWidth: CGFloat = 362

    // Native cell widths (Figma 305:3037).
    private static let asteriskW: CGFloat = 38
    private static let titleW: CGFloat = 180
    private static let timeW: CGFloat = 51
    private static let genreW: CGFloat = 93

    /// Visual height stays 38 pt; row extends to 44 pt for Apple HIG tap targets.
    private static let rowHitHeight: CGFloat = max(nativeHeight, FigmaTheme.minTouchTarget)
    private static var rowHitPad: CGFloat { (rowHitHeight - nativeHeight) / 2 }

    var body: some View {
        let border = FigmaTheme.hairlineBorder

        HStack(spacing: 0) {
            // 1: asterisk cell — outer perimeter only (no left divider).
            Button(action: onAsteriskTap) {
                FigmaAsterisk(color: Color(red: 1, green: 0, blue: 0))
                    .frame(width: 14, height: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .frame(width: Self.asteriskW, height: Self.nativeHeight)
            .frame(minHeight: Self.rowHitHeight)
            .contentShape(Rectangle())

            // 2: song name cell — 180 pt, tail-truncates, shares left border.
            metaCellLabel(songTitle)
                .frame(width: Self.titleW, height: Self.nativeHeight)
                .frame(minHeight: Self.rowHitHeight)
                .contentShape(Rectangle())
                .overlay(alignment: .leading) { verticalDivider(color: border) }

            // 3: time cell — fixed 51 pt, shares left border.
            metaCellLabel(timeText, allowTruncate: false)
                .frame(width: Self.timeW, height: Self.nativeHeight)
                .frame(minHeight: Self.rowHitHeight)
                .contentShape(Rectangle())
                .overlay(alignment: .leading) { verticalDivider(color: border) }

            // 4: genre cell — fixed 93 pt to match Figma, shares left border.
            metaCellLabel(genre)
                .frame(width: Self.genreW, height: Self.nativeHeight)
                .frame(minHeight: Self.rowHitHeight)
                .contentShape(Rectangle())
                .overlay(alignment: .leading) { verticalDivider(color: border) }
        }
        .frame(width: Self.nativeWidth, height: Self.nativeHeight)
        .padding(.vertical, Self.rowHitPad)
        .background(Color.white)
        .overlay(
            Rectangle().stroke(border, lineWidth: FigmaTheme.snapToPixel(1))
        )
        // Host gives us the full screen width — we sit centered so the
        // *outside* horizontal spacing absorbs width differences.
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: Cell helpers

    @ViewBuilder
    private func metaCellLabel(_ text: String, allowTruncate: Bool = true) -> some View {
        Text(text)
            .font(.custom("Helvetica", size: 12))
            .tracking(-0.96)
            .foregroundStyle(Color.black)
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
            .frame(maxWidth: allowTruncate ? .infinity : nil, maxHeight: .infinity)
            .padding(.horizontal, 12)
    }

    private func verticalDivider(color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: FigmaTheme.snapToPixel(1))
            .frame(maxHeight: .infinity)
    }
}

// MARK: - FigmaAsterisk
//
// 8-pointed red "burst" matching Figma node `305:3121` ("Repeat group 1").
// The source SVG uses Gaussian-blur + displacement-map + turbulence filters
// that iOS image rendering can't reproduce, so we recreate the burst
// natively as 4 thin red capsules rotated 0° / 45° / 90° / 135° — each
// capsule covers two of the 8 rays through its rounded ends, producing the
// clean sunburst silhouette without the fluff filter.
//

/// Native re-creation of Figma's red 8-ray asterisk burst.
struct FigmaAsterisk: View {
    var color: Color = .red

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let rayThickness = side * 0.16
            let rayLength = side * 0.96

            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(color)
                        .frame(width: rayThickness, height: rayLength)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Previews

#Preview("Hero meta strip — Figma 305:3037") {
    VStack(spacing: 20) {
        // Narrow host (iPhone SE-ish) — strip stays 362, margins shrink.
        FigmaHeroMetaStrip(
            songTitle: "SHORT TITLE",
            timeText: "22:00",
            genre: "ROCK"
        )
        .frame(width: 360)

        // Native (Figma reference) width.
        FigmaHeroMetaStrip(
            songTitle: "SONG NAME XXXXXXXXXXXX",
            timeText: "22:00",
            genre: "GENRE"
        )
        .frame(width: 402)

        // Wide host — strip stays 362, margins grow.
        FigmaHeroMetaStrip(
            songTitle: "REALLY REALLY LONG SONG TITLE THAT MUST TRUNCATE WITH ELLIPSIS",
            timeText: "1:02:34",
            genre: "ELECTRONICA"
        )
        .frame(width: 430)
    }
    .padding(.vertical, 24)
    .background(T3Color.surfacePrimary)
}

#Preview("FigmaAsterisk") {
    FigmaAsterisk()
        .frame(width: 56, height: 56)
        .padding()
        .background(Color.white)
}
