import SwiftUI

// MARK: - Saved crate hybrid tab (`401:3699` / `401:3779`)

/// WEB | CRATES — single canvas tone (`SavedCrateCanvasChrome.fieldFill`); orange cap only — no black well / white halos.
struct SavedCrateHybridTabSwitch: View {
    @Binding var mode: SavedCrateViewMode
    var scale: CGFloat = 1

    private static let nativeWidth: CGFloat = 148.333
    private static let nativeHeight: CGFloat = 40

    var body: some View {
        let s = scale
        let dividerW = max(1, s)
        let trackW = Self.nativeWidth * s
        let halfW = (trackW - dividerW) / 2
        let h = Self.nativeHeight * s

        HStack(spacing: 0) {
            tabHalf(title: "WEB", isActive: mode == .web, width: halfW, height: h, scale: s) {
                mode = .web
            }
            .accessibilityIdentifier("savedCrate.mode.web")

            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: dividerW, height: h * 0.62)

            tabHalf(title: "CRATES", isActive: mode == .crate, width: halfW, height: h, scale: s) {
                mode = .crate
            }
            .accessibilityIdentifier("savedCrate.mode.crate")
        }
        .frame(width: trackW, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 0.833 * s))
        .overlay {
            RoundedRectangle(cornerRadius: 0.833 * s)
                .stroke(Color(red: 0.05, green: 0.05, blue: 0.04).opacity(0.1), lineWidth: 0.5 * s)
        }
        .accessibilityIdentifier("savedCrate.modePicker")
    }

    private func tabHalf(
        title: String,
        isActive: Bool,
        width: CGFloat,
        height: CGFloat,
        scale s: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                SavedCrateCanvasChrome.fieldFill

                if isActive {
                    RoundedRectangle(cornerRadius: 8.333 * s)
                        .fill(FigmaTheme.orangeAccent)
                        .frame(width: 70.833 * s, height: 35.417 * s)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8.333 * s)
                                .stroke(Color(red: 0.06, green: 0.06, blue: 0.055).opacity(0.28), lineWidth: 1 * s)
                        }
                        .shadow(color: .black.opacity(0.14), radius: 3 * s, x: 0, y: 1.5 * s)
                        .offset(y: 0.5 * s)
                }

                Text(title)
                    .font(FigmaFont.mono(15 * s))
                    .foregroundStyle(
                        isActive
                            ? .white
                            : Color(red: 0.19, green: 0.19, blue: 0.19).opacity(0.72)
                    )
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(FigmaKeyPressStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        SavedCrateHybridTabSwitch(mode: .constant(.web))
        SavedCrateHybridTabSwitch(mode: .constant(.crate))
    }
    .padding()
    .background(SavedCrateCanvasChrome.fieldFill)
}
