import SwiftUI
import UIKit

// MARK: - Center-anchored pinch zoom (UIScrollView — same model as Photos / Maps)

/// Wraps SwiftUI canvas content in a `UIScrollView` so pinch zoom scales from the viewport
/// center and keeps the focal region stable instead of drifting with a top-leading anchor.
struct SavedCrateWebZoomScrollView<Content: View>: UIViewRepresentable {
    let canvasSize: CGSize
    let graphCenter: CGPoint
    let content: Content

    var minimumZoomScale: CGFloat = 0.45
    var maximumZoomScale: CGFloat = 3.25

    init(
        canvasSize: CGSize,
        graphCenter: CGPoint,
        minimumZoomScale: CGFloat = 0.45,
        maximumZoomScale: CGFloat = 3.25,
        @ViewBuilder content: () -> Content
    ) {
        self.canvasSize = canvasSize
        self.graphCenter = graphCenter
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = minimumZoomScale
        scroll.maximumZoomScale = maximumZoomScale
        scroll.bouncesZoom = true
        scroll.backgroundColor = .white
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.alwaysBounceVertical = true
        scroll.alwaysBounceHorizontal = true

        let container = UIView(frame: CGRect(origin: .zero, size: canvasSize))
        container.backgroundColor = .clear
        scroll.addSubview(container)

        let host = UIHostingController(rootView: content)
        host.view.frame = container.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear
        container.addSubview(host.view)

        context.coordinator.scrollView = scroll
        context.coordinator.container = container
        context.coordinator.hosting = host
        context.coordinator.canvasSize = canvasSize
        context.coordinator.graphCenter = graphCenter

        scroll.contentSize = canvasSize
        DispatchQueue.main.async {
            context.coordinator.centerOnGraph(animated: false)
            context.coordinator.centerZoomedView()
        }

        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.hosting?.rootView = content

        let sizeChanged = context.coordinator.canvasSize != canvasSize
        if sizeChanged {
            context.coordinator.canvasSize = canvasSize
            context.coordinator.container?.frame = CGRect(origin: .zero, size: canvasSize)
            scroll.contentSize = canvasSize
            context.coordinator.hosting?.view.frame = context.coordinator.container?.bounds ?? .zero
        }

        let centerMoved = context.coordinator.graphCenter != graphCenter
        context.coordinator.graphCenter = graphCenter

        if sizeChanged || centerMoved {
            DispatchQueue.main.async {
                context.coordinator.centerOnGraph(animated: false)
                context.coordinator.centerZoomedView()
            }
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var container: UIView?
        var hosting: UIHostingController<Content>?
        var canvasSize: CGSize = .zero
        var graphCenter: CGPoint = .zero

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            container
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerZoomedView()
        }

        /// Letterbox the zoomed canvas when it is smaller than the viewport.
        func centerZoomedView() {
            guard let scrollView, let container else { return }
            let bounds = scrollView.bounds.size
            var frame = container.frame

            if frame.width < bounds.width {
                frame.origin.x = (bounds.width - frame.width) / 2
            } else {
                frame.origin.x = 0
            }

            if frame.height < bounds.height {
                frame.origin.y = (bounds.height - frame.height) / 2
            } else {
                frame.origin.y = 0
            }

            container.frame = frame
        }

        /// Scroll so `graphCenter` sits in the middle of the visible viewport.
        func centerOnGraph(animated: Bool) {
            guard let scrollView else { return }
            let scale = scrollView.zoomScale
            let contentW = scrollView.contentSize.width
            let contentH = scrollView.contentSize.height
            let targetX = graphCenter.x * scale - scrollView.bounds.width * 0.5
            let targetY = graphCenter.y * scale - scrollView.bounds.height * 0.5

            let maxX = max(0, contentW - scrollView.bounds.width)
            let maxY = max(0, contentH - scrollView.bounds.height)

            let offset = CGPoint(
                x: min(max(0, targetX), maxX),
                y: min(max(0, targetY), maxY)
            )
            scrollView.setContentOffset(offset, animated: animated)
        }
    }
}
