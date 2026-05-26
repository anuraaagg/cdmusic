import SwiftUI

// MARK: - Saved crate hybrid tab (`401:3699` / `401:3779`)

/// Braun-style WEB | CRATES key — orange seated cap on black well + cream flat half.
struct SavedCrateHybridTabSwitch: View {
    @Binding var mode: SavedCrateViewMode
    var scale: CGFloat = 1

    private static let nativeWidth: CGFloat = 148.333
    private static let nativeHeight: CGFloat = 40

    var body: some View {
        let s = scale
        let halfW = 74.167 * s
        let h = Self.nativeHeight * s

        HStack(spacing: 0) {
            tabHalf(title: "WEB", isActive: mode == .web, width: halfW, height: h, scale: s) {
                mode = .web
            }
            .accessibilityIdentifier("savedCrate.mode.web")

            tabHalf(title: "CRATES", isActive: mode == .crate, width: halfW, height: h, scale: s) {
                mode = .crate
            }
            .accessibilityIdentifier("savedCrate.mode.crate")
        }
        .frame(width: Self.nativeWidth * s, height: h)
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
                RoundedRectangle(cornerRadius: 0.833 * s)
                    .fill(isActive ? Color.black : Color(red: 0.88, green: 0.86, blue: 0.85))

                if isActive {
                    RoundedRectangle(cornerRadius: 8.333 * s)
                        .fill(FigmaTheme.orangeAccent)
                        .frame(width: 70.833 * s, height: 35.417 * s)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8.333 * s)
                                .stroke(Color.white.opacity(0.85), lineWidth: 1.25 * s)
                        }
                        .shadow(color: .black.opacity(0.48), radius: 6.667 * s, x: 6.667 * s, y: 6.667 * s)
                        .offset(y: 0.5 * s)
                }

                Text(title)
                    .font(FigmaFont.mono(15 * s))
                    .foregroundStyle(isActive ? .white : Color(red: 0.19, green: 0.19, blue: 0.19))
            }
            .overlay {
                if !isActive {
                    RoundedRectangle(cornerRadius: 0.833 * s)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.5 * s)
                }
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
    .background(Color.white)
}
