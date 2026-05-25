import SwiftUI

// MARK: - Figma knob — SVG `337:5621` / node `332:4666`
//
// Native SwiftUI recreation (iOS ignores SVG filter chains). All geometry is
// proportional to the **132 pt platter** diameter; the 178 × 178 viewBox only
// adds shadow bleed around the dish.
//
// Layers (back → front):
//   1. Platter — cream gradient disc + rim + drop shadow
//   2. Contact shadow — blurred wedge under the cap (parallax on jiggle)
//   3. Cap overlays — jog marks, etc.
//   4. Raised cap — cream gradient + rim + layered shadow + gloss

private enum Knob3375621 {
    static let platterDiameter: CGFloat = 132
    static let capDiameter: CGFloat = 61.0322          // r 30.5161 × 2
    static let rimStroke: CGFloat = 0.709677

    static let creamLight = Color(red: 228 / 255, green: 222 / 255, blue: 219 / 255) // #E4DEDB
    static let creamDark  = Color(red: 230 / 255, green: 225 / 255, blue: 223 / 255) // #E6E1DF
    static let rimTint    = Color(red: 209 / 255, green: 204 / 255, blue: 200 / 255) // #D1CCC8

    static func s(_ diameter: CGFloat, _ design: CGFloat) -> CGFloat {
        diameter * design / platterDiameter
    }
}

struct FigmaKnob3324666<CapOverlay: View>: View {
    /// Platter diameter — design default **132 pt**.
    let diameter: CGFloat
    var capJiggle: CGSize = .zero
    var shadowParallaxScale: CGFloat = 0.28
    var innerPressed: Bool = false

    @ViewBuilder var capOverlayBelowTactile: () -> CapOverlay

    var body: some View {
        let d = diameter
        let capD = Knob3375621.s(d, Knob3375621.capDiameter)
        let rim = max(0.5, Knob3375621.s(d, Knob3375621.rimStroke))

        ZStack {
            platter(diameter: d, rim: rim)

            contactShadow(diameter: d)
                .offset(
                    x: -capJiggle.width * shadowParallaxScale,
                    y: -capJiggle.height * shadowParallaxScale
                )

            Group {
                capOverlayBelowTactile()

                raisedCap(diameter: capD, rim: rim)
            }
            .offset(capJiggle)
            .scaleEffect(innerPressed ? 0.965 : 1, anchor: .center)
            .offset(y: innerPressed ? max(1, diameter * 0.012) : 0)
            .animation(.spring(response: 0.11, dampingFraction: 0.62), value: innerPressed)
        }
        .frame(width: d, height: d)
    }

    // MARK: - Platter

    private func platter(diameter d: CGFloat, rim: CGFloat) -> some View {
        Circle()
            .fill(creamFill)
            .overlay(
                Circle()
                    .strokeBorder(rimGradient, lineWidth: rim)
            )
            .overlay(platterHighlight(diameter: d))
            .frame(width: d, height: d)
            .shadow(
                color: .black.opacity(0.25),
                radius: Knob3375621.s(d, 11.3548),
                x: Knob3375621.s(d, 11.3548),
                y: Knob3375621.s(d, 11.3548)
            )
            .allowsHitTesting(false)
    }

    private func platterHighlight(diameter d: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.55), Color.clear],
                    center: UnitPoint(x: 0.28, y: 0.26),
                    startRadius: 0,
                    endRadius: d * 0.52
                )
            )
            .blendMode(.softLight)
            .allowsHitTesting(false)
    }

    // MARK: - Contact shadow (`filter1_f` wedge)

    private func contactShadow(diameter d: CGFloat) -> some View {
        Ellipse()
            .fill(Color(red: 15 / 255, green: 14 / 255, blue: 14 / 255).opacity(0.35))
            .frame(width: d * 0.36, height: d * 0.14)
            .blur(radius: Knob3375621.s(d, 5.67742))
            .offset(x: d * 0.14, y: d * 0.20)
            .allowsHitTesting(false)
    }

    // MARK: - Raised cap

    private func raisedCap(diameter capD: CGFloat, rim: CGFloat) -> some View {
        Circle()
            .fill(creamFill)
            .overlay(
                Circle()
                    .strokeBorder(rimGradient, lineWidth: rim)
            )
            .overlay(capHighlight(diameter: capD))
            .frame(width: capD, height: capD)
            .shadow(color: .black.opacity(0.15), radius: Knob3375621.s(capD, 5.67742), x: Knob3375621.s(capD, 2.83871), y: Knob3375621.s(capD, 2.83871))
            .shadow(color: .black.opacity(0.40), radius: Knob3375621.s(capD, 11.3548), x: Knob3375621.s(capD, 11.3548), y: Knob3375621.s(capD, 11.3548))
            .allowsHitTesting(false)
    }

    private func capHighlight(diameter capD: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(capD * 0.08)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.28), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: capD * 0.72, height: capD * 0.10)
                .rotationEffect(.degrees(-18))
                .offset(y: -capD * 0.14)
        }
        .blendMode(.softLight)
        .allowsHitTesting(false)
    }

    private var creamFill: LinearGradient {
        LinearGradient(
            colors: [Knob3375621.creamLight, Knob3375621.creamDark],
            startPoint: UnitPoint(x: 0.08, y: 0.08),
            endPoint: UnitPoint(x: 0.92, y: 0.92)
        )
    }

    private var rimGradient: LinearGradient {
        LinearGradient(
            colors: [Knob3375621.rimTint, Knob3375621.rimTint.opacity(0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension FigmaKnob3324666 where CapOverlay == EmptyView {
    init(
        diameter: CGFloat = Knob3375621.platterDiameter,
        capJiggle: CGSize = .zero,
        shadowParallaxScale: CGFloat = 0.28,
        innerPressed: Bool = false
    ) {
        self.init(
            diameter: diameter,
            capJiggle: capJiggle,
            shadowParallaxScale: shadowParallaxScale,
            innerPressed: innerPressed,
            capOverlayBelowTactile: { EmptyView() }
        )
    }
}

// MARK: - Preview

#Preview("Knob 337:5621 @132") {
    StatefulKnob4666Preview()
        .padding(48)
        .background(FigmaTheme.panelGrey)
}

private struct StatefulKnob4666Preview: View {
    @State private var jig = CGSize.zero

    var body: some View {
        FigmaKnob3324666(diameter: 132, capJiggle: jig) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 4, height: 4)
                    .offset(y: -132 * 0.225)
            }
            .frame(width: 132, height: 132)
            .rotationEffect(.degrees(12))
            .allowsHitTesting(false)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { jig = CGSize(width: $0.translation.width * 0.35, height: $0.translation.height * 0.35) }
                .onEnded { _ in withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { jig = .zero } }
        )
    }
}
