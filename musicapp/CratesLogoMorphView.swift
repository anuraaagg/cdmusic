import SwiftUI

struct CratesLogoMorphView: View {
    var morphProgress: CGFloat
    var savedCount: Int
    var scale: CGFloat = 1

    private var c: FigmaTheme.Crate.Type { FigmaTheme.Crate.self }

    var body: some View {
        let s = scale
        let t = max(0, min(1, morphProgress))

        VStack(spacing: c.headerInnerGap * s) {
            ZStack {
                dotMatrixTitle(s: s, spread: t)
                    .opacity(1.0 - t * 0.85)

                dropContainer(s: s, t: t)
                    .opacity(t)
            }
            .frame(height: c.headerRowHeight * s)

            Rectangle()
                .fill(FigmaTheme.textDark.opacity(0.75))
                .frame(height: c.dividerHeight * s)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: t)
    }

    private func dotMatrixTitle(s: CGFloat, spread: CGFloat) -> some View {
        Text("CRATES")
            .font(FigmaFont.libraryTitle(c.titleFontSize * s))
            .tracking((-0.96 + Double(spread) * 4) * Double(s))
            .foregroundStyle(FigmaTheme.textDark)
            .scaleEffect(x: 1 + spread * 0.06, y: 1 + spread * 0.18, anchor: .center)
    }

    private func dropContainer(s: CGFloat, t: CGFloat) -> some View {
        VStack(spacing: 6 * s) {
            Text("DROP IT IN")
                .font(.custom("Helvetica", size: 9 * s).weight(.bold))
                .tracking(0.22 * s)
                .foregroundStyle(FigmaTheme.textDark.opacity(0.55))

            RoundedRectangle(cornerRadius: 8 * s, style: .continuous)
                .stroke(FigmaTheme.textDark.opacity(0.35 + t * 0.25), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 8 * s, style: .continuous)
                        .fill(Color(red: 0.18, green: 0.35, blue: 0.22).opacity(0.12 + t * 0.2))
                )
                .frame(height: 52 * s)
                .overlay {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 14 * s, weight: .medium))
                        .foregroundStyle(FigmaTheme.textDark.opacity(0.4))
                }

            Text("\(savedCount) in crate")
                .font(.custom("Helvetica", size: 10 * s))
                .foregroundStyle(FigmaTheme.textDark.opacity(0.45))
        }
        .scaleEffect(0.92 + t * 0.08)
    }
}
