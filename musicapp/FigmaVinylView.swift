import SwiftUI

/// Figma `305:2757` — carousel vinyl cell: sleeve (`Subtract`) · hub · spindle.
///
/// Layer order matches Figma DOM — sleeve artwork sits above the centre hub.
struct FigmaVinylView: View {
    let sleeveIndex: Int
    var discArtwork: UIImage?
    var labelColor: UIColor = UIColor(T3Color.labelDark.opacity(0.35))
    var rotation: Double = 0
    /// Figma carousel cell is 200 × 200 @402 reference.
    var cellSize: CGFloat = 200

    /// Figma `305:2758` hub — 67.754 pt in a 200 pt cell.
    private var hubDiameter: CGFloat { cellSize * 67.754 / 200 }
    private var hubCenterX: CGFloat { cellSize * (65.65 + 67.754 / 2) / 200 }
    private var hubCenterY: CGFloat { cellSize * (66.1 + 67.754 / 2) / 200 }

    var body: some View {
        let cell = cellSize

        ZStack {
            centerHub(cell: cell)

            Image(uiImage: compositeDiscImage)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: cell, height: cell)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: cell, height: cell)
        .clipShape(Circle())
    }

    /// Figma `305:2758` / `305:2759` — white hub + spindle glyph.
    private func centerHub(cell: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: hubDiameter, height: hubDiameter)

            Image(FigmaImage.vinylSpindle)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: hubDiameter * 0.22, height: hubDiameter * 0.22)
        }
        .position(x: hubCenterX, y: hubCenterY)
        .allowsHitTesting(false)
    }

    private var compositeDiscImage: UIImage {
        UIImageFigma.compositeVinylSleeve(
            sleeveAssetName: FigmaImage.vinylSleeve(sleeveIndex),
            artwork: discArtwork,
            labelColor: labelColor
        )
    }
}

#Preview("Vinyl cell — 200pt") {
    HStack(spacing: 8) {
        ForEach(0..<3, id: \.self) { i in
            FigmaVinylView(sleeveIndex: i, cellSize: 120)
        }
    }
    .padding()
    .background(FigmaTheme.crateInner)
}
