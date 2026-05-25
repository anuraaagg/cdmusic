import SwiftUI

// MARK: - FigmaButtonHalf
//
// Half-width keys — Figma dev export for PREV / NEXT / SHUFFLE / REPEAT.
//
// Top row (flat caps):
//   PREV    176×48  corner 12    orange fill   label 20.33 pt
//   NEXT    176×48  corner 11.29 cream fill    label 20.33 pt
//
// Bottom row (seated caps in black well):
//   SHUFFLE 176×48  well corner 1.08  cap 168.09×45.84  corner 10.79
//   REPEAT  same geometry, darker cap fill

struct FigmaButtonHalf: View {
    let label: String
    var variant: Variant = .orange
    var isActive: Bool = false
    var flex: Bool = true
    var scale: CGFloat = 1
    let action: () -> Void

    @Environment(\.figmaKeyPressed) private var isPressed

    static let nativeHeight: CGFloat = 48
    static let nativeWidth: CGFloat = 176

    var body: some View {
        Button(action: action) {
            keyAssembly
                .frame(maxWidth: flex ? .infinity : Self.nativeWidth * scale)
                .frame(height: Self.nativeHeight * scale)
        }
        .buttonStyle(FigmaKeyPressStyle())
    }

    @ViewBuilder
    private var keyAssembly: some View {
        let geom = variant.geometry
        let spec = variant.spec
        let fill = isActive ? Self.activeFill : spec.fill
        let pressDepth = geom.pressDepth * scale

        let cap = keyCap(fill: fill, spec: spec, geom: geom)
            .scaleEffect(isPressed ? 0.985 : 1, anchor: .center)
            .offset(y: isPressed ? pressDepth : 0)
            .shadow(
                color: Color.black.opacity(isPressed ? 0.06 : geom.dropShadowOpacity),
                radius: isPressed ? geom.dropShadowBlur * scale * 0.15 : geom.dropShadowBlur * scale,
                x: isPressed ? geom.dropShadowX * scale * 0.15 : geom.dropShadowX * scale,
                y: isPressed ? geom.dropShadowY * scale * 0.15 : geom.dropShadowY * scale
            )
            .brightness(isPressed ? -0.08 : 0)

        if geom.usesWell {
            ZStack {
                wellRecess(corner: geom.wellCorner * scale, pressed: isPressed)
                cap
                    .frame(width: geom.capWidth * scale, height: geom.capHeight * scale)
            }
        } else {
            cap
                .overlay { flatKeyRecess(corner: geom.corner * scale, pressed: isPressed) }
        }
    }

    /// Black well with inner lip — Braun recessed socket.
    private func wellRecess(corner: CGFloat, pressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(Color.black)
            .overlay {
                RoundedRectangle(cornerRadius: max(0, corner - 0.5))
                    .stroke(Color.white.opacity(pressed ? 0.10 : 0.06), lineWidth: 0.5)
                    .blur(radius: 0.4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(pressed ? 0.72 : 0.55),
                                Color.black.opacity(0.18),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
    }

    /// Flat keys simulate a shallow recess on press.
    private func flatKeyRecess(corner: CGFloat, pressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(
                LinearGradient(
                    colors: pressed
                        ? [Color.black.opacity(0.28), Color.black.opacity(0.10), Color.clear]
                        : [Color.clear, Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.multiply)
            .allowsHitTesting(false)
    }

    private func keyCap(fill: Color, spec: ColorSpec, geom: VariantGeometry) -> some View {
        let corner = geom.corner * scale

        return ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(fill)
                .overlay { capFaceShading(corner: corner, pressed: isPressed) }
                .overlay { capStroke(corner: corner, geom: geom) }

            Text(label.uppercased())
                .font(FigmaFont.mono(geom.fontSize * scale))
                .foregroundStyle(spec.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.52)
                .offset(x: geom.labelOffsetX * scale, y: geom.labelOffsetY * scale)
        }
    }

    @ViewBuilder
    private func capStroke(corner: CGFloat, geom: VariantGeometry) -> some View {
        ForEach(Array(geom.strokes.enumerated()), id: \.offset) { _, stroke in
            RoundedRectangle(cornerRadius: corner)
                .inset(by: stroke.inset * scale)
                .stroke(Color.white.opacity(stroke.opacity), lineWidth: stroke.width * scale)
        }
    }

    @ViewBuilder
    private func capFaceShading(corner: CGFloat, pressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(
                LinearGradient(
                    colors: pressed
                        ? [Color.black.opacity(0.22), Color.black.opacity(0.12), Color.black.opacity(0.04)]
                        : [Color.black.opacity(0.10), Color.black.opacity(0.04), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.multiply)
            .allowsHitTesting(false)
    }

    static let activeFill = Color(red: 0.95, green: 0.29, blue: 0.05)
}

// MARK: - Geometry

private struct StrokeSpec {
    let inset: CGFloat
    let width: CGFloat
    let opacity: Double
}

private struct VariantGeometry {
    let corner: CGFloat
    let fontSize: CGFloat
    let labelOffsetX: CGFloat
    let labelOffsetY: CGFloat
    let strokes: [StrokeSpec]
    let usesWell: Bool
    let wellCorner: CGFloat
    let capWidth: CGFloat
    let capHeight: CGFloat
    let dropShadowX: CGFloat
    let dropShadowY: CGFloat
    let dropShadowBlur: CGFloat
    let dropShadowOpacity: Double
    let pressDepth: CGFloat

    static let prev = VariantGeometry(
        corner: 12,
        fontSize: 20.33,
        labelOffsetX: 0,
        labelOffsetY: 0.42,
        strokes: [StrokeSpec(inset: 1, width: 1, opacity: 0.50)],
        usesWell: false, wellCorner: 0, capWidth: 176, capHeight: 48,
        dropShadowX: 9.04, dropShadowY: 9.04, dropShadowBlur: 18.07, dropShadowOpacity: 0.48,
        pressDepth: 3
    )

    static let next = VariantGeometry(
        corner: 11.29,
        fontSize: 20.33,
        labelOffsetX: -0.48,
        labelOffsetY: 0.42,
        strokes: [
            StrokeSpec(inset: 0.85, width: 0.85, opacity: 0.30),
            StrokeSpec(inset: 0.85, width: 0.85, opacity: 0.20),
        ],
        usesWell: false, wellCorner: 0, capWidth: 176, capHeight: 48,
        dropShadowX: 9.04, dropShadowY: 9.04, dropShadowBlur: 18.07, dropShadowOpacity: 0.48,
        pressDepth: 3
    )

    static let shuffle = VariantGeometry(
        corner: 10.79,
        fontSize: 19.42,
        labelOffsetX: 0.08,
        labelOffsetY: 0.44,
        strokes: [
            StrokeSpec(inset: 0.81, width: 0.81, opacity: 1.00),
            StrokeSpec(inset: 0.81, width: 0.81, opacity: 0.80),
        ],
        usesWell: true, wellCorner: 1.08, capWidth: 168.09, capHeight: 45.84,
        dropShadowX: 8.63, dropShadowY: 8.63, dropShadowBlur: 17.26, dropShadowOpacity: 0.48,
        pressDepth: 3
    )

    static let `repeat` = VariantGeometry(
        corner: 10.79,
        fontSize: 19.42,
        labelOffsetX: -0.42,
        labelOffsetY: 0.44,
        strokes: [
            StrokeSpec(inset: 0.81, width: 0.81, opacity: 0.30),
            StrokeSpec(inset: 0.81, width: 0.81, opacity: 0.20),
        ],
        usesWell: true, wellCorner: 1.08, capWidth: 168.09, capHeight: 45.84,
        dropShadowX: 8.63, dropShadowY: 8.63, dropShadowBlur: 17.26, dropShadowOpacity: 0.48,
        pressDepth: 3
    )
}

// MARK: - Colour-named call sites

extension FigmaButtonHalf {
    static func orange(
        label: String = "PREV",
        flex: Bool = true,
        scale: CGFloat = 1,
        action: @escaping () -> Void
    ) -> FigmaButtonHalf {
        FigmaButtonHalf(label: label, variant: .orange, flex: flex, scale: scale, action: action)
    }

    static func cream(
        label: String = "NEXT",
        flex: Bool = true,
        scale: CGFloat = 1,
        action: @escaping () -> Void
    ) -> FigmaButtonHalf {
        FigmaButtonHalf(label: label, variant: .cream, flex: flex, scale: scale, action: action)
    }

    static func midGrey(
        label: String = "SHUFFLE",
        isActive: Bool = false,
        flex: Bool = true,
        scale: CGFloat = 1,
        action: @escaping () -> Void
    ) -> FigmaButtonHalf {
        FigmaButtonHalf(label: label, variant: .midGrey, isActive: isActive, flex: flex, scale: scale, action: action)
    }

    static func dark(
        label: String = "REPEAT",
        isActive: Bool = false,
        flex: Bool = true,
        scale: CGFloat = 1,
        action: @escaping () -> Void
    ) -> FigmaButtonHalf {
        FigmaButtonHalf(label: label, variant: .dark, isActive: isActive, flex: flex, scale: scale, action: action)
    }
}

// MARK: - Variants

extension FigmaButtonHalf {
    enum Variant {
        case orange
        case cream
        case midGrey
        case dark

        fileprivate var spec: ColorSpec {
            switch self {
            case .orange:
                return ColorSpec(
                    fill: Color(red: 0.95, green: 0.29, blue: 0.05),
                    textColor: .white
                )
            case .cream:
                return ColorSpec(
                    fill: Color(red: 0.84, green: 0.82, blue: 0.82),
                    textColor: Color(red: 0.19, green: 0.19, blue: 0.19)
                )
            case .midGrey:
                return ColorSpec(
                    fill: Color(red: 0.69, green: 0.68, blue: 0.68),
                    textColor: .white
                )
            case .dark:
                return ColorSpec(
                    fill: Color(red: 0.14, green: 0.14, blue: 0.14),
                    textColor: .white
                )
            }
        }

        fileprivate var geometry: VariantGeometry {
            switch self {
            case .orange:  return .prev
            case .cream:   return .next
            case .midGrey: return .shuffle
            case .dark:    return .repeat
            }
        }
    }

    fileprivate struct ColorSpec {
        let fill: Color
        let textColor: Color
    }
}

// MARK: - Press environment + style (shared by half + square keys)

struct FigmaKeyPressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var figmaKeyPressed: Bool {
        get { self[FigmaKeyPressedKey.self] }
        set { self[FigmaKeyPressedKey.self] = newValue }
    }
}

struct FigmaKeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.figmaKeyPressed, configuration.isPressed)
            .animation(.spring(response: 0.11, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("PREV + NEXT") {
    HStack(spacing: 10) {
        FigmaButtonHalf.orange(flex: true) {}
        FigmaButtonHalf.cream(flex: true) {}
    }
    .padding(20)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}

#Preview("SHUFFLE + REPEAT") {
    HStack(spacing: 10) {
        FigmaButtonHalf.midGrey(flex: true) {}
        FigmaButtonHalf.dark(flex: true) {}
    }
    .padding(20)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}

#Preview("Full 2×2 grid") {
    VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 10) {
            FigmaButtonHalf.orange(flex: true) {}
            FigmaButtonHalf.cream(flex: true) {}
        }
        HStack(spacing: 10) {
            FigmaButtonHalf.midGrey(flex: true) {}
            FigmaButtonHalf.dark(flex: true) {}
        }
    }
    .padding(20)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}
