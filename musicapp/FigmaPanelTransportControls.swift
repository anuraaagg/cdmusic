import SwiftUI

// MARK: - Visual screen side pods — Figma `469:11569` / `465:11203` / `465:11197`
//
// Both pods export @4× → **120 × 120 pt** logical. Transport row is `space-between`.

/// Figma `465:11203` — D7 vent pod (120 × 120 pt).
struct FigmaD7VentPod: View {
    var scale: CGFloat = 1

    var body: some View {
        podImage(FigmaImage.d7VentGrille)
            .accessibilityIdentifier("control.d7Vent")
            .accessibilityLabel("Speaker vent")
    }

    @ViewBuilder
    private func podImage(_ name: String) -> some View {
        let side = FigmaTheme.visualPodSize * scale
        Image(name)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFit()
            .frame(width: side, height: side)
    }
}

/// Figma `465:11197` — G4 meter pod (120 × 120 pt) + animated needle overlay.
struct FigmaG4MeterPod: View {
    var needleAngle: Double
    var scale: CGFloat = 1

    var body: some View {
        let side = FigmaTheme.visualPodSize * scale
        let dialR = FigmaTheme.sidePodInner * scale * 0.47

        ZStack {
            Image(FigmaImage.g4MeterDial)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: side, height: side)

            Capsule()
                .fill(Color(red: 0.92, green: 0.90, blue: 0.88))
                .frame(width: max(1.4, 2.0 * scale), height: dialR * 0.72)
                .offset(y: -dialR * 0.34)
                .rotationEffect(.degrees(needleAngle))
                .shadow(color: .black.opacity(0.3), radius: 0.5, y: 0.5)
                .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.72), value: needleAngle)
        }
        .frame(width: side, height: side)
        .accessibilityIdentifier("control.g4Meter")
        .accessibilityLabel("Tempo meter")
    }
}

#Preview("Visual transport pods") {
    HStack {
        FigmaD7VentPod(scale: 1)
        Spacer()
        FigmaG4MeterPod(needleAngle: 18, scale: 1)
    }
    .padding(.horizontal, 20)
    .frame(width: 362)
    .background(FigmaTheme.visualPanelCream)
}
