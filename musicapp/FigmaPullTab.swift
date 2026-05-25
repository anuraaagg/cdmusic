import SwiftUI

// MARK: - FigmaPullTab
//
// Faithful re-implementation of the Figma drag-handle "pull tab"
// (file: SuMsVkITTi0ZVnpJGHC5U7, node: 305:3309 with children 305:3310 + 305:3311).
//
// Geometry (native, before `scale`):
//   • Group: 56 × 18 pt, centred horizontally on the sheet
//   • Back layer (305:3310): 56 × 18 rounded-12 all corners, light→dark
//     vertical gradient, **white** 1pt drop-shadow at y = +2 ("metal shelf"
//     glint along the bottom edge)
//   • Front layer (305:3311): 56 × 12, top-leading/trailing radius 12 pt,
//     bottom-leading/trailing radius 5 pt, dark→mid→light vertical gradient,
//     **white** 1pt drop-shadow at y = -2 ("metal lip" glint along the top
//     edge). Drawn on top of the back layer, so only the bottom 6 pt of the
//     back layer peeks out, giving the tab its physical "shelf" depth.
//
// The two layers share the same horizontal extent (56pt), so the back layer
// only shows beneath the front, never around the sides.
//

/// Metallic pull-tab drag handle used at the top of the player bottom-sheet
/// chrome. Pass the host's `figmaLayoutScale` via `scale` so the geometry,
/// gradients and white-edge highlights track the rest of the panel.
struct FigmaPullTab: View {
    /// Uniform scale factor against Figma's 402 pt reference width.
    var scale: CGFloat = 1

    /// Native group width in Figma.
    static let nativeWidth: CGFloat = 56
    /// Native group height in Figma.
    static let nativeHeight: CGFloat = 18

    var body: some View {
        let s = scale
        let w = Self.nativeWidth * s
        let backH = Self.nativeHeight * s
        let frontH = 12 * s

        ZStack(alignment: .top) {
            // Back layer (305:3310) — provides the 6 pt shelf below the cap.
            RoundedRectangle(cornerRadius: 12 * s, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            // 10.479%: #DADCDB (light grey)
                            .init(color: Color(red: 218 / 255, green: 220 / 255, blue: 219 / 255), location: 0.10),
                            // 100%: #636363 (dark grey) — Figma stop sits at 106.38 % so the gradient resolves to dark grey at the bottom.
                            .init(color: Color(red: 99 / 255, green: 99 / 255, blue: 99 / 255), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: w, height: backH)
                // White 1pt blur at y = +2 — the rear shelf glint.
                .shadow(color: Color.white.opacity(0.45), radius: 0.5 * s, x: 0, y: 2 * s)

            // Front layer (305:3311) — the dark cap. Sharper bottom corners
            // (5 pt) emphasise the shelf seam where the back layer emerges.
            UnevenRoundedRectangle(
                topLeadingRadius: 12 * s,
                bottomLeadingRadius: 5 * s,
                bottomTrailingRadius: 5 * s,
                topTrailingRadius: 12 * s,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    stops: [
                        // 14.706%: #393939 (very dark)
                        .init(color: Color(red: 0x39 / 255, green: 0x39 / 255, blue: 0x39 / 255), location: 0.147),
                        // 52.221%: #505050 (mid)
                        .init(color: Color(red: 0x50 / 255, green: 0x50 / 255, blue: 0x50 / 255), location: 0.522),
                        // 100%: #C9C9CA (almost white) — Figma stop at 105.88 %.
                        .init(color: Color(red: 0xC9 / 255, green: 0xC9 / 255, blue: 0xCA / 255), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: w, height: frontH)
            // White 1pt blur at y = -2 — the cap-top glint.
            .shadow(color: Color.white.opacity(0.45), radius: 0.5 * s, x: 0, y: -2 * s)
        }
        .frame(width: w, height: backH)
        // Subtle outer drop shadow so the tab sits convincingly on the cream panel.
        .shadow(color: Color.black.opacity(0.18), radius: 1.5 * s, x: 0, y: 1 * s)
    }
}

// MARK: - Preview

#Preview("FigmaPullTab — Figma 305:3309") {
    VStack(spacing: 24) {
        FigmaPullTab(scale: 1)
        FigmaPullTab(scale: 1.5)
        FigmaPullTab(scale: 2.5)
    }
    .padding(40)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}
