import SwiftUI
import UIKit

/// Procedurally drawn vinyl for the crate drop sheet — concentric grooves + label + fixed hub.
/// Used instead of bitmap sleeve art for the **gesture** target so we can tune depth and motion cleanly.
struct CrateProceduralDropVinyl: View {
    var discArtwork: UIImage?
    var labelColor: UIColor
    /// Album label / cover spin (playback); hub stays fixed like `FigmaVinylView`.
    var rotation: Double = 0
    var diameter: CGFloat

    private var hubDiameter: CGFloat { diameter * 0.28 }

    var body: some View {
        ZStack {
            groovesLayer
            labelLayer
                .rotationEffect(.degrees(rotation))
            hubLayer
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        /// Grooves + hub opt out of hit testing — without this the tappable region shrinks to the label disc only.
        .contentShape(Circle())
    }

    private var groovesLayer: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.08, green: 0.08, blue: 0.09),
                            Color(red: 0.12, green: 0.12, blue: 0.13),
                            Color(red: 0.05, green: 0.05, blue: 0.06)
                        ],
                        center: .center,
                        startRadius: diameter * 0.12,
                        endRadius: diameter * 0.55
                    )
                )
            ForEach(0..<18, id: \.self) { i in
                let t = CGFloat(i) / 18
                Circle()
                    .stroke(
                        Color.white.opacity(0.035 + Double(t) * 0.045),
                        lineWidth: max(0.35, diameter * 0.004 * (1 - t * 0.4))
                    )
                    .scaleEffect(0.92 - t * 0.38)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var labelLayer: some View {
        let labelR = diameter * 0.36
        Group {
            if let discArtwork {
                Image(uiImage: discArtwork)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: labelR * 2, height: labelR * 2)
                    .clipped()
            } else {
                Color(uiColor: labelColor)
                    .frame(width: labelR * 2, height: labelR * 2)
            }
        }
        .frame(width: labelR * 2, height: labelR * 2)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: max(1, diameter * 0.006)))
    }

    private var hubLayer: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.98), Color(white: 0.88)],
                        center: .center,
                        startRadius: 0,
                        endRadius: hubDiameter * 0.5
                    )
                )
                .frame(width: hubDiameter, height: hubDiameter)
                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))

            Image(FigmaImage.vinylSpindle)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: hubDiameter * 0.22, height: hubDiameter * 0.22)
        }
        .allowsHitTesting(false)
    }
}
