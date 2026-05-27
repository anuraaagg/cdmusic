import SwiftUI

/// PNG crate + draggable CD in one canvas — offset layout, high-priority drag.
struct SavedCrate2DScene<Disc: View>: View {
    let crateWidth: CGFloat
    var discOffset: CGSize = .zero
    var discScale: CGFloat = 1
    var discHitPadding: CGFloat = 40
    var dragEnabled: Bool = false
    var onDragChanged: ((DragGesture.Value) -> Void)?
    var onDragEnded: ((DragGesture.Value) -> Void)?
    @GestureState private var isDragging = false
    @ViewBuilder var disc: () -> Disc

    private var metrics: SavedCrate2DLayout.Metrics {
        SavedCrate2DLayout.metrics(forCrateWidth: crateWidth)
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

            disc()
                .scaleEffect(discScale)
                .frame(width: metrics.discDiameter, height: metrics.discDiameter)
                .frame(
                    width: metrics.discDiameter + discHitPadding * 2,
                    height: metrics.discDiameter + discHitPadding * 2
                )
                .contentShape(Circle())
                .offset(
                    x: discOffset.width,
                    y: metrics.discRestCenter.y - metrics.discDiameter * 0.5 - discHitPadding + discOffset.height
                )
                .highPriorityGesture(dragEnabled ? drag : nil)
        }
        .frame(width: metrics.crateWidth, height: metrics.totalHeight, alignment: .top)
        .coordinateSpace(name: SavedCrate2DLayout.coordinateSpaceName)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(SavedCrate2DLayout.coordinateSpaceName))
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
                onDragChanged?(value)
            }
            .onEnded { value in
                onDragEnded?(value)
            }
    }
}
