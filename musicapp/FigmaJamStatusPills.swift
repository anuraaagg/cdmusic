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
        let pillR = min(m.pillCorner * s, m.rowHeight * s / 2)
        let overlap = m.pillsVisualOverlap * s
        let hp = m.pillHPad * s
        let vp = m.pillVPad * s
        let statusW = m.statusPillWidth * s

        HStack(spacing: -overlap) {
            Text(statusText)
                .font(FigmaFont.status(m.statusFont * s))
                .foregroundStyle(FigmaTheme.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, hp)
                .padding(.vertical, vp)
                .frame(width: statusW, alignment: .center)
                .background(FigmaTheme.jamPillFill)
                .clipShape(RoundedRectangle(cornerRadius: pillR, style: .continuous))

            Text(counterText.uppercased())
                .font(FigmaFont.counter(m.counterFont * s))
                .foregroundStyle(FigmaTheme.jamCounterText)
                .lineSpacing((m.counterLineHeight - m.counterFont) * s)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, hp)
                .padding(.vertical, vp)
                .fixedSize(horizontal: true, vertical: false)
                .background(FigmaTheme.jamPillFill)
                .clipShape(RoundedRectangle(cornerRadius: pillR, style: .continuous))
                .zIndex(1)
        }
    }
}

// MARK: - Preview

#Preview("Status pills — overlap, no border") {
    FigmaJamStatusPills(statusText: "not playing", counterText: "3-5")
        .padding(24)
        .background(FigmaTheme.panelGrey)
}
