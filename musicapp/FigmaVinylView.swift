import SwiftUI

/// Figma `356:2873` — carousel vinyl cell: full-bleed artwork · fixed centre hub.
///
/// Layer order matches Figma — rotating label art sits beneath the static hub
/// (`356:2874` / `Group 1000006064`); only the artwork changes per slot.
struct FigmaVinylView: View {
    let sleeveIndex: Int
    var discArtwork: UIImage?
    var labelColor: UIColor = UIColor(T3Color.labelDark.opacity(0.35))
    var rotation: Double = 0
    /// Figma carousel cell is 200 × 200 @402 reference.
    var cellSize: CGFloat = 200

    /// Slightly smaller than Figma `356:2874` (67.754 / 200) so sleeve titles stay visible.
    private var hubDiameter: CGFloat { cellSize * 0.28 }

    var body: some View {
        ZStack {
            artworkLayer
                .rotationEffect(.degrees(rotation))

            centerHub
        }
        .frame(width: cellSize, height: cellSize)
        .clipShape(Circle())
    }

    /// Figma `356:2878` (`Subtract`) — artwork fills the full 200 pt disc.
    @ViewBuilder
    private var artworkLayer: some View {
        if let discArtwork {
            Image(uiImage: discArtwork)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: cellSize, height: cellSize)
                .background(Color(uiColor: labelColor))
        } else if let sleeve = UIImage(named: FigmaImage.vinylSleeve(sleeveIndex)) {
            Image(uiImage: sleeve)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: cellSize, height: cellSize)
        } else {
            Color(uiColor: labelColor)
                .frame(width: cellSize, height: cellSize)
        }
    }

    /// Figma `356:2874` — white hub + spindle; does not rotate with the label art.
    private var centerHub: some View {
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
        .allowsHitTesting(false)
    }
}

#Preview("Vinyl cell — 356:2873") {
    HStack(spacing: 8) {
        ForEach(0..<3, id: \.self) { i in
            FigmaVinylView(sleeveIndex: i, cellSize: 120)
        }
    }
    .padding()
    .background(FigmaTheme.crateInner)
}
