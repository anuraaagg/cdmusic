import SwiftUI

// MARK: - Crate tab — PNG crate + one front CD

struct SavedCrateFrontStackView: View {
    let moments: [SavedMoment]
    @Binding var frontIndex: Int
    var popOutProgress: CGFloat = 0
    var artworkFor: (SavedMoment) -> UIImage?
    var labelColorFor: (SavedMoment) -> UIColor = { _ in UIColor(T3Color.labelDark.opacity(0.35)) }
    var allowsInteraction: Bool = true
    var onSelect: ((SavedMoment) -> Void)?

    private let crateWidth: CGFloat = 268

    private var displayMoments: [SavedMoment] {
        Array(moments.prefix(12))
    }

    private var metrics: SavedCrate2DLayout.Metrics {
        SavedCrate2DLayout.metrics(forCrateWidth: crateWidth)
    }

    private var frontMoment: SavedMoment? {
        guard displayMoments.indices.contains(frontIndex) else { return displayMoments.first }
        return displayMoments[frontIndex]
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
            Image(FigmaImage.savedCrateGreen)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: metrics.crateWidth, height: metrics.crateHeight)
                .accessibilityHidden(true)

            if let moment = frontMoment {
                frontDisc(moment: moment)
            }
        }
        .frame(width: metrics.crateWidth, height: metrics.totalHeight, alignment: .top)
        .contentShape(Rectangle())
        .gesture(flipGesture)
        .onChange(of: displayMoments.count) { _, count in
            if frontIndex >= count {
                frontIndex = max(0, count - 1)
            }
        }
    }

    private func frontDisc(moment: SavedMoment) -> some View {
        let pop = frontIndex == 0 ? popOutProgress : 0
        let diameter = metrics.discDiameter * (1 + pop * 0.04)

        return FigmaVinylView(
            sleeveIndex: frontIndex,
            discArtwork: artworkFor(moment),
            labelColor: labelColorFor(moment),
            cellSize: diameter
        )
        .crateDiscCardFlip(tiltX: -10, perspective: 0.65)
        .offset(
            x: 0,
            y: metrics.discRestCenter.y - metrics.discDiameter * 0.5 + pop * -18
        )
        .onTapGesture {
            guard allowsInteraction else { return }
            onSelect?(moment)
        }
        .accessibilityLabel("Saved disc")
    }

    private var flipGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard allowsInteraction, displayMoments.count > 1 else { return }
                if value.translation.width < -28, frontIndex < displayMoments.count - 1 {
                    withAnimation(.easeOut(duration: 0.2)) { frontIndex += 1 }
                } else if value.translation.width > 28, frontIndex > 0 {
                    withAnimation(.easeOut(duration: 0.2)) { frontIndex -= 1 }
                }
            }
    }
}
