import SwiftUI

// MARK: - FigmaJamStatusPills
//
// Overlapping status + counter capsules from Figma `332:4653`–`332:4657`.
//
// Layout: `HStack(spacing: -16)` — the counter tucks under the status curve.
// No stroke; the overlap itself creates the visual notch between the two pills.
//
// Reference (@402 pt) — row height **64** (`332:4647`); pills use −16 overlap, no stroke.
//   • status pill **192** pt wide, pad 24 × 20, corner 48, **22** pt status type, `#0d0c0a`
//   • counter pill  hug content, same pad/corner, Roboto Mono 16 / 24 lh, uppercase
//   • fill          surface/primary `#f8f7f4`
//   • overlap       16 pt (`mr-[-16px]` on status in Figma)

struct FigmaJamStatusPills: View {
    let statusText: String
    let counterText: String
    var scale: CGFloat = 1

    var body: some View {
        let m = FigmaTheme.JamToolbar.self
        let s = scale
        let clusterH = m.innerClusterHeight * s
        let pillR = min(m.pillCorner * s, clusterH / 2)
        let overlap = m.pillsVisualOverlap * s
        let hp = m.pillHPad * s
        let statusW = m.statusPillWidth * s
        let counterMinW = m.counterMinWidth * s

        HStack(alignment: .center, spacing: -overlap) {
            statusPill(
                text: statusText,
                fontSize: m.statusFont * s,
                width: statusW,
                height: clusterH,
                hPad: hp,
                corner: pillR
            )

            counterPill(
                text: counterText.uppercased(),
                fontSize: m.counterFont * s,
                lineHeight: m.counterLineHeight * s,
                minWidth: counterMinW,
                height: clusterH,
                hPad: hp,
                corner: pillR
            )
            .zIndex(1)
        }
        .frame(height: clusterH, alignment: .center)
    }

    private func statusPill(
        text: String,
        fontSize: CGFloat,
        width: CGFloat,
        height: CGFloat,
        hPad: CGFloat,
        corner: CGFloat
    ) -> some View {
        Text(text)
            .font(FigmaFont.status(fontSize))
            .foregroundStyle(FigmaTheme.textDark)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, hPad)
            .frame(width: width, height: height, alignment: .center)
            .background(FigmaTheme.jamPillFill)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private func counterPill(
        text: String,
        fontSize: CGFloat,
        lineHeight: CGFloat,
        minWidth: CGFloat,
        height: CGFloat,
        hPad: CGFloat,
        corner: CGFloat
    ) -> some View {
        Text(text)
            .font(FigmaFont.counter(fontSize))
            .foregroundStyle(FigmaTheme.jamCounterText)
            .lineSpacing(lineHeight - fontSize)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, hPad)
            .frame(minWidth: minWidth)
            .frame(height: height, alignment: .center)
            .background(FigmaTheme.jamPillFill)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

// MARK: - Preview

#Preview("Status pills — overlap, no border") {
    FigmaJamStatusPills(statusText: "not playing", counterText: "3-5")
        .padding(24)
        .background(FigmaTheme.panelGrey)
}
