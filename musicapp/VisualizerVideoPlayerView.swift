import AVFoundation
import SwiftUI

@MainActor
final class VisualizerVideoController: ObservableObject {
    let player = AVPlayer()

    private var loopObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var loadedURL: URL?

    deinit {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }

    func playRandomClip() {
        let urls = VisualizerVideoCatalog.allURLs()
        guard !urls.isEmpty else { return }

        let url: URL
        if urls.count == 1 {
            url = urls[0]
        } else {
            let others = urls.filter { $0 != loadedURL }
            url = (others.isEmpty ? urls : others).randomElement() ?? urls[0]
        }

        guard loadedURL != url || player.currentItem == nil else {
            player.play()
            return
        }

        loadedURL = url
        load(url: url)
    }

    func pause() {
        player.pause()
    }

    func resumeIfNeeded() {
        guard player.currentItem != nil else {
            playRandomClip()
            return
        }
        if player.rate == 0 {
            player.play()
        }
    }

    private func load(url: URL) {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        let item = AVPlayerItem(url: url)
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.player.seek(to: .zero)
            self.player.play()
        }

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            Task { @MainActor in
                self?.player.play()
            }
        }

        player.replaceCurrentItem(with: item)
        player.isMuted = true
        player.play()
    }
}

/// Looping muted visualizer clip — plain AVPlayerLayer (no SwiftUI shader on video; overlays handle VHS).
struct VisualizerVideoPlayerView: View {
    @ObservedObject var controller: VisualizerVideoController

    var body: some View {
        VisualizerPlayerLayerView(player: controller.player) {
            controller.resumeIfNeeded()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .allowsHitTesting(false)
    }
}

private struct VisualizerPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    let onLayerReady: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onLayerReady: onLayerReady)
    }

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.onBoundsReady = { context.coordinator.notifyReady() }
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
        uiView.playerLayer.videoGravity = .resizeAspectFill
        uiView.onBoundsReady = { context.coordinator.notifyReady() }
        uiView.setNeedsLayout()
    }

    final class Coordinator {
        private let onLayerReady: () -> Void

        init(onLayerReady: @escaping () -> Void) {
            self.onLayerReady = onLayerReady
        }

        func notifyReady() {
            onLayerReady()
        }
    }
}

private final class PlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    var onBoundsReady: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        if bounds.width > 2, bounds.height > 2, window != nil {
            onBoundsReady?()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}
