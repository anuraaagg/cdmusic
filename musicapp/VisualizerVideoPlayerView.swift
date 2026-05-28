import AVFoundation
import SwiftUI

@MainActor
final class VisualizerVideoController: ObservableObject {
    let player = AVPlayer()

    @Published private(set) var isReversed = false

    private var loopObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var reverseBoundaryObserver: Any?
    private var loadedURL: URL?
    private var pendingRate: Float = 1

    deinit {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }

    var scrubFraction: Double {
        guard let duration = currentDuration, duration > 0 else { return 0 }
        return min(1, max(0, player.currentTime().seconds / duration))
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
            applyPendingRate()
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
        applyPendingRate()
    }

    func syncPlaybackRate(_ speed: Double) {
        let base = Float(max(0.35, min(2.5, speed)))
        pendingRate = isReversed ? -base : base
        applyPendingRate()
    }

    func toggleReverse() {
        isReversed.toggle()
        if isReversed {
            installReverseBoundaryObserverIfNeeded()
        } else {
            removeReverseBoundaryObserver()
        }
        syncPlaybackRate(Double(abs(pendingRate)))
    }

    func scrub(byFraction delta: Double) {
        seek(toFraction: scrubFraction + delta)
    }

    func seek(toFraction fraction: Double) {
        guard let duration = currentDuration, duration > 0 else { return }
        let clamped = min(1, max(0, fraction))
        let seconds = duration * clamped
        player.seek(
            to: CMTime(seconds: seconds, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func seek(bySeconds seconds: Double) {
        guard let duration = currentDuration else { return }
        let next = min(duration, max(0, player.currentTime().seconds + seconds))
        seek(toFraction: next / duration)
    }

    func scratch(deltaDegrees: Double) {
        scrub(byFraction: deltaDegrees / 360.0 * 0.18)
    }

    private var currentDuration: Double? {
        guard let item = player.currentItem else { return nil }
        let seconds = item.duration.seconds
        guard seconds.isFinite, seconds > 0 else { return nil }
        return seconds
    }

    private func load(url: URL) {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
        if let reverseBoundaryObserver {
            player.removeTimeObserver(reverseBoundaryObserver)
            self.reverseBoundaryObserver = nil
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
            guard let self, !self.isReversed else { return }
            self.player.seek(to: .zero)
            self.applyPendingRate()
        }

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            Task { @MainActor in
                self?.installReverseBoundaryObserverIfNeeded()
                self?.applyPendingRate()
            }
        }

        player.replaceCurrentItem(with: item)
        player.isMuted = true
        applyPendingRate()
    }

    private func applyPendingRate() {
        guard player.currentItem != nil else { return }
        player.rate = pendingRate
        if pendingRate != 0, player.rate == 0 {
            player.play()
            player.rate = pendingRate
        }
    }

    private func installReverseBoundaryObserverIfNeeded() {
        guard isReversed else { return }
        guard reverseBoundaryObserver == nil else { return }
        reverseBoundaryObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.08, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self, self.isReversed else { return }
            guard time.seconds <= 0.04, let duration = self.currentDuration else { return }
            self.player.seek(
                to: CMTime(seconds: max(0, duration - 0.05), preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            ) { _ in
                self.applyPendingRate()
            }
        }
    }

    private func removeReverseBoundaryObserver() {
        if let reverseBoundaryObserver {
            player.removeTimeObserver(reverseBoundaryObserver)
            self.reverseBoundaryObserver = nil
        }
    }
}

/// Looping muted visualizer clip with channel shader + joystick-driven rate/scrub.
struct VisualizerVideoPlayerView: View {
    var channel: VisualizerChannel
    var time: Double
    var bass: Double
    var mid: Double
    var high: Double
    var speed: Double

    @ObservedObject var controller: VisualizerVideoController

    var body: some View {
        VisualizerPlayerLayerView(player: controller.player) {
            controller.resumeIfNeeded()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .visualEffect { content, proxy in
            content
                .distortionEffect(
                    warpShader(size: proxy.size),
                    maxSampleOffset: CGSize(width: 12, height: 12)
                )
                .colorEffect(colorShader(size: proxy.size))
        }
        .allowsHitTesting(false)
    }

    private func warpShader(size: CGSize) -> Shader {
        let p = channel.metalParams
        return ShaderLibrary.videoVHSWarp(
            .float(Float(size.width)),
            .float(Float(size.height)),
            .float(Float(time)),
            .float(Float(bass)),
            .float(Float(mid)),
            .float(Float(high)),
            .float(Float(p.hue)),
            .float(Float(p.grain)),
            .float(Float(p.chroma)),
            .float(Float(speed))
        )
    }

    private func colorShader(size: CGSize) -> Shader {
        let p = channel.metalParams
        return ShaderLibrary.videoVHSColor(
            .float(Float(size.width)),
            .float(Float(size.height)),
            .float(Float(time)),
            .float(Float(bass)),
            .float(Float(mid)),
            .float(Float(high)),
            .float(Float(p.hue)),
            .float(Float(p.grain * (0.85 + speed * 0.15))),
            .float(Float(p.chroma)),
            .float(Float(1.32))
        )
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
