import SwiftUI

// MARK: - FigmaPanelControls
//
// Native SwiftUI re-implementations of the small visual primitives that
// the original Figma export shipped as SVGs containing iOS-unsupported
// features. iOS asset-catalog SVG rendering:
//
//   • Ignores `feGaussianBlur` / `feColorMatrix` / `feBlend` filter chains,
//     so the `knob_outer`, `knob_shadow_core`, `knob_tactile` assets all
//     collapsed to flat circles with no 3D shading.
//   • Doesn't resolve CSS custom properties (`fill="var(--fill-0, black)"`),
//     so `dial_a2`, `dial_center`, `vol_chevron`, `vol_slider_track`
//     rendered as transparent or empty shapes.
//   • Renders sub-pixel strokes (the chevron's 0.545 pt stroke) inconsistently
//     — at typical screen sizes it disappears entirely.
//
// These views provide pixel-stable native replacements driven entirely by
// SwiftUI `Shape` + gradient + shadow primitives. Use them anywhere the
// matching `Image(FigmaImage.knobOuter)` / `Image(FigmaImage.dialA2)` /
// `Image(FigmaImage.volChevron)` references used to live.

// MARK: - JAM dial plate (Figma 305:3326 / 305:3327)

/// Black dial face with white centre splash + three tick marks — Figma `332:4652` / `A2`.
struct FigmaJamDial: View {
    /// Diameter of the black dial disc.
    var size: CGFloat = 45.714
    /// Continuous spin while music is playing (degrees).
    var spinDegrees: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)

            dialTick(at: .degrees(0))
            dialTick(at: .degrees(120))
            dialTick(at: .degrees(-120))

            FigmaDialCenter()
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.28 * (8.49 / 9.65))
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(spinDegrees))
    }

    /// White rounded tick — native size 1.787 × 4.793 @ 45.714 dial.
    private func dialTick(at angle: Angle) -> some View {
        RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
            .fill(Color.white)
            .frame(width: size * 0.039, height: size * 0.105)
            .offset(y: -size * 0.38)
            .rotationEffect(angle)
    }
}

/// White Y / splash shape that sits at the centre of the JAM dial.
///
/// Path traced from Figma node `305:3327` (viewBox 9.64566 × 8.49265). We
/// re-anchor it to a unit rect and let SwiftUI scale it to whatever size
/// the caller requests, so the silhouette stays crisp regardless of zoom.
private struct FigmaDialCenter: Shape {
    func path(in rect: CGRect) -> Path {
        // Native viewBox: width 9.64566 × height 8.49265.
        let vbW: CGFloat = 9.64566
        let vbH: CGFloat = 8.49265
        let sx = rect.width / vbW
        let sy = rect.height / vbH
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var path = Path()
        path.move(to: p(0.10595, 6.89773))
        // Bottom-left curve up to the foot of the V.
        path.addCurve(
            to: p(0.0297506, 7.20138),
            control1: p(0.00411138, 6.96296),
            control2: p(-0.0307185, 7.09665)
        )
        path.addLine(to: p(0.690723, 8.34622))
        path.addCurve(
            to: p(0.995613, 8.43002),
            control1: p(0.752023, 8.45239),
            control2: p(0.887805, 8.4884)
        )
        // Sweep across the bottom (the open bowl of the splash).
        path.addCurve(
            to: p(8.66379, 8.46395),
            control1: p(3.4688, 7.09072),
            control2: p(6.35405, 7.19024)
        )
        path.addCurve(
            to: p(8.97024, 8.38094),
            control1: p(8.77178, 8.52351),
            control2: p(8.90857, 8.48774)
        )
        path.addLine(to: p(9.61586, 7.26269))
        path.addCurve(
            to: p(9.53132, 6.95389),
            control1: p(9.67825, 7.15462),
            control2: p(9.63918, 7.01664)
        )
        // Right shoulder rising up to the top-right anchor.
        path.addCurve(
            to: p(6.6365, 4.04477),
            control1: p(8.36696, 6.27643),
            control2: p(7.35832, 5.29502)
        )
        path.addCurve(
            to: p(5.56625, 0.223541),
            control1: p(5.93972, 2.83792),
            control2: p(5.5935, 1.52487)
        )
        path.addCurve(
            to: p(5.34113, 0),
            control1: p(5.56367, 0.100354),
            control2: p(5.46435, 0)
        )
        path.addLine(to: p(4.00807, 0))
        path.addCurve(
            to: p(3.78291, 0.226621),
            control1: p(3.88368, 0),
            control2: p(3.78389, 0.102239)
        )
        // Left shoulder back down to the start point.
        path.addCurve(
            to: p(0.10595, 6.89773),
            control1: p(3.76235, 2.84943),
            control2: p(2.45011, 5.39625)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Jog wheel knob base (Figma 305:3331 — `knob_outer` + `knob_tactile`)

/// Native recreation of the 3D knob drum from Figma. Replaces the chain
/// of three SVGs (`knob_outer`, `knob_shadow_core`, `knob_tactile`) that
/// rely on filter chains iOS doesn't honor.
///
/// Approximation strategy:
///   1. Diagonal cream gradient base — matches the SVG `paint0_linear_0_49`
///      stops (#E4DEDB → #E6E1DF) but rotated for depth.
///   2. Top-left radial highlight (warm white) for the "soft-light" pass
///      from the SVG's filter stack.
///   3. Bottom-right radial darken for the inner shadow accents.
///   4. Outer rim stroke with a subtle white-to-shadow gradient so the
///      drum looks like it's machined out of the panel.
///   5. Real `.shadow` cast onto the parent for the bottom-right drop.
struct FigmaJogKnobBase: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 232 / 255, green: 226 / 255, blue: 222 / 255),
                            Color(red: 212 / 255, green: 206 / 255, blue: 202 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Soft top-left highlight (warm white).
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.0)
                        ],
                        center: UnitPoint(x: 0.30, y: 0.28),
                        startRadius: 0,
                        endRadius: diameter * 0.55
                    )
                )
                .allowsHitTesting(false)

            // Bottom-right darken — matches the heavy inner shadow at dx=10,dy=10.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.16)
                        ],
                        center: UnitPoint(x: 0.78, y: 0.78),
                        startRadius: diameter * 0.15,
                        endRadius: diameter * 0.58
                    )
                )
                .allowsHitTesting(false)

            // Crisp rim with a hint of bevel.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color(red: 0.78, green: 0.76, blue: 0.74).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(0.6, diameter * 0.005)
                )
                .allowsHitTesting(false)
        }
        .frame(width: diameter, height: diameter)
        // Bottom-right drop — corresponds to the SVG filter's drop shadow.
        .shadow(color: .black.opacity(0.22), radius: diameter * 0.06, x: diameter * 0.035, y: diameter * 0.045)
        // Subtle wider halo to ground the drum in the panel.
        .shadow(color: .black.opacity(0.08), radius: diameter * 0.10, x: 0, y: diameter * 0.02)
    }
}

/// Subtle dark contact shadow that lives just under the knob cap.
/// Approximates the `knob_shadow_core` SVG (a single blurred dark ellipse
/// with `feGaussianBlur stdDeviation=5.16`).
struct FigmaJogKnobContactShadow: View {
    let diameter: CGFloat

    var body: some View {
        Ellipse()
            .fill(Color.black.opacity(0.18))
            .frame(width: diameter * 0.62, height: diameter * 0.18)
            .blur(radius: diameter * 0.04)
            .offset(y: diameter * 0.30)
            .allowsHitTesting(false)
    }
}

/// Faint tactile gloss / texture pass over the knob cap. Stand-in for the
/// `knob_tactile` SVG that originally carried multiple inner shadows and a
/// soft-light blend.
struct FigmaJogKnobTactileGloss: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            // Diagonal lighting streak across the top half.
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: diameter * 0.78, height: diameter * 0.12)
                .rotationEffect(.degrees(-20))
                .offset(y: -diameter * 0.18)

            // Soft inner ring — separates the cap from the dish.
            Circle()
                .strokeBorder(Color.black.opacity(0.06), lineWidth: max(0.4, diameter * 0.004))
                .padding(diameter * 0.015)
        }
        .frame(width: diameter, height: diameter)
        .blendMode(.softLight)
        .opacity(0.9)
        .allowsHitTesting(false)
    }
}

// MARK: - VOL chevron (Figma `305:2701` / `305:2702`)

/// Orange "L"-bracket that frames the VOL label top + bottom.
/// Replaces `vol_chevron` whose 0.545 pt CSS-var stroke was effectively
/// invisible on device.
struct FigmaVolChevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Anchor at top-right and run across the top edge, then down the
        // left edge — produces a ⌐-shaped bracket. The mirrored bottom
        // copy is drawn by the caller using `scaleEffect(y: -1)`.
        let inset: CGFloat = 0.5  // keep stroke inside bounds
        path.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        return path
    }
}

// MARK: - VOL slider track (Figma 305:3441)

/// Dark vertical capsule for the volume track. Replaces the
/// `vol_slider_track` SVG that depended on filters + CSS vars.
struct FigmaVolSliderTrack: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let capsuleW = max(2, width * 0.16)

        ZStack {
            // Mid-line tick (Figma `Line 4` — horizontal hairline at 50 %).
            Rectangle()
                .fill(Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255))
                .frame(width: width * 0.8, height: 0.6)

            // Dark capsule rail running top → bottom.
            RoundedRectangle(cornerRadius: capsuleW / 2, style: .continuous)
                .fill(Color(red: 34 / 255, green: 23 / 255, blue: 23 / 255))
                .frame(width: capsuleW, height: height)
                .overlay(
                    // Subtle inner highlight on the top-left edge.
                    RoundedRectangle(cornerRadius: capsuleW / 2, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        .padding(0.5)
                        .mask(
                            RoundedRectangle(cornerRadius: capsuleW / 2, style: .continuous)
                                .frame(width: capsuleW, height: height)
                        )
                )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Previews

#Preview("FigmaJamDial") {
    FigmaJamDial(size: 64)
        .padding(16)
        .background(T3Color.surfacePrimary)
}

#Preview("FigmaJogKnobBase") {
    ZStack {
        FigmaJogKnobContactShadow(diameter: 160)
        FigmaJogKnobBase(diameter: 160)
        FigmaJogKnobTactileGloss(diameter: 160)
    }
    .padding(40)
    .background(FigmaTheme.panelGrey)
}

#Preview("VOL — 337:5622") {
    FigmaVolControl3375622(vm: MusicPlayerViewModel(), height: 131.941)
        .padding(40)
        .background(FigmaTheme.panelGrey)
}
