import SwiftUI

// MARK: - FigmaSquareButton
//
// Seated square keys from Figma `310:3476`
// (PLAY = `310:3477`, PAUSE = `310:3478`). Cap master `298:13917`.
//
// File: SuMsVkITTi0ZVnpJGHC5U7 (testtingclaudexfigma).
//
// Reference sizing (54 pt cap — Figma `310:3477` export):
//   • column        2 × 54 + 11.321 gap  =  119.321 pt
//   • well          54 × 54, black, corner 0.61
//   • cap           51.57 × 51.57, inset 1.215 pt
//   • cap corner    6.07
//   • cap stroke    0.46 px white @ 50 %, inset 0.46
//   • drop shadow   x 4.85  y 4.85  blur 9.71  rgba(0,0,0,0.73)
//   • PLAY fill     rgb(0.33, 0.32, 0.31)
//   • PAUSE fill    bgdarkgrey #242323
//
// Type:
//   • label   Sometype Mono Regular 10.92 pt, white, top 6.74 %, centered
//   • star    Red Hat Mono Regular 17.6 pt,   white, left 15.73 %, bottom 3.75 %

struct FigmaSquareButton: View {
    let label: String
    var variant: Variant = .play
    var scale: CGFloat = 1
    let action: () -> Void

    @Environment(\.figmaKeyPressed) private var isPressed

    /// Cap is 54 × 54 in Figma reference space.
    static let nativeSize: CGFloat = 54

    /// Seated cap face — Figma inner rect `310:3477`.
    static let capSize: CGFloat = 51.57

    /// Tray and cap corner radii from Figma dev export.
    static let wellCornerRadius: CGFloat = 0.61
    static let capCornerRadius: CGFloat = 6.07

    /// Vertical gap between the PLAY and PAUSE caps inside `310:3476`.
    static let columnGap: CGFloat = 11.321

    /// Total column height = 2 caps + gap. Matches `310:3476` bbox (119.321 pt).
    static let columnHeight: CGFloat = nativeSize * 2 + columnGap

    var body: some View {
        Button(action: action) {
            keyAssembly
                .frame(width: Self.nativeSize * scale,
                       height: Self.nativeSize * scale)
        }
        .buttonStyle(FigmaKeyPressStyle())
    }

    // MARK: - Layers

    /// Black tray (`buttonWell`) holding the floating cap.
    private var keyAssembly: some View {
        let pressDepth = 2.5 * scale

        return ZStack {
            RoundedRectangle(cornerRadius: Self.wellCornerRadius * scale)
                .fill(Color.black)
                .overlay {
                    RoundedRectangle(cornerRadius: max(0, Self.wellCornerRadius * scale - 0.5))
                        .stroke(Color.white.opacity(isPressed ? 0.10 : 0.06), lineWidth: 0.5)
                        .blur(radius: 0.4)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Self.wellCornerRadius * scale)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(isPressed ? 0.72 : 0.55),
                                    Color.black.opacity(0.18),
                                    Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }

            keyCap
                .frame(width: Self.capSize * scale, height: Self.capSize * scale)
                .scaleEffect(isPressed ? 0.985 : 1, anchor: .center)
                .offset(y: isPressed ? pressDepth : 0)
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.08 : 0.73),
                    radius: isPressed ? 9.71 * scale * 0.15 : 9.71 * scale,
                    x: isPressed ? 4.85 * scale * 0.15 : 4.85 * scale,
                    y: isPressed ? 4.85 * scale * 0.15 : 4.85 * scale
                )
                .brightness(isPressed ? -0.08 : 0)
        }
    }

    /// Seated cap (`keyCap`) — fill, inner shading, white stroke, content.
    private var keyCap: some View {
        let corner = Self.capCornerRadius * scale
        let strokeW = 0.46 * scale

        return ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(variant.fill)
                .overlay(insetHighlight(corner: corner, pressed: isPressed))
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .inset(by: strokeW * 0.5)
                        .stroke(Color.white.opacity(0.50), lineWidth: strokeW)
                )

            capContent
        }
    }

    @ViewBuilder
    private var capContent: some View {
        Text(label.uppercased())
            .font(FigmaFont.mono(10.92 * scale))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .fixedSize()
            .offset(y: -10.92 * scale)

        if variant.showsAsterisk {
            Text("*")
                .font(FigmaFont.redHatMono(17.6 * scale))
                .foregroundStyle(Color.white)
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, Self.nativeSize * 0.1573 * scale)
                .padding(.bottom, Self.nativeSize * 0.0375 * scale)
        }
    }

    private func insetHighlight(corner: CGFloat, pressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(
                LinearGradient(
                    colors: pressed
                        ? [Color.black.opacity(0.22), Color.black.opacity(0.10), Color.black.opacity(0.04)]
                        : [Color.black.opacity(0.10), Color.black.opacity(0.04), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.multiply)
            .allowsHitTesting(false)
    }
}

// MARK: - Variants

extension FigmaSquareButton {
    enum Variant {
        case play
        case pause

        fileprivate var fill: Color {
            switch self {
            case .play:  return Color(red: 0.33, green: 0.32, blue: 0.31)
            case .pause: return Color(red: 36 / 255, green: 35 / 255, blue: 35 / 255) // #242323 bgdarkgrey
            }
        }

        fileprivate var showsAsterisk: Bool { self == .pause }
    }

    static func play(scale: CGFloat = 1, action: @escaping () -> Void) -> FigmaSquareButton {
        FigmaSquareButton(label: "PLAY", variant: .play, scale: scale, action: action)
    }

    static func pause(scale: CGFloat = 1, action: @escaping () -> Void) -> FigmaSquareButton {
        FigmaSquareButton(label: "PAUSE", variant: .pause, scale: scale, action: action)
    }
}

// MARK: - Previews

#Preview("PLAY / PAUSE column — 310:3476") {
    VStack(spacing: FigmaSquareButton.columnGap) {
        FigmaSquareButton.play {}
        FigmaSquareButton.pause {}
    }
    .padding(24)
    .background(FigmaTheme.panelGrey)
}

#Preview("Scaled 1.5×") {
    VStack(spacing: FigmaSquareButton.columnGap * 1.5) {
        FigmaSquareButton.play(scale: 1.5) {}
        FigmaSquareButton.pause(scale: 1.5) {}
    }
    .padding(32)
    .background(FigmaTheme.panelGrey)
}
