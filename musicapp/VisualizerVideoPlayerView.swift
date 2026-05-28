import AVFoundation
import MetalKit
import SwiftUI

@MainActor
final class VisualizerVideoController: ObservableObject {
    let player = AVPlayer()
    let renderer = VisualizerVideoRenderer()

    @Published private(set) var isReversed = false
    @Published private(set) var hasLoadedClip = false

    private var loopObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var reverseBoundaryObserver: Any?
    private var videoOutput: AVPlayerItemVideoOutput?
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
        guard !urls.isEmpty else {
            hasLoadedClip = false
            return
        }

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
        hasLoadedClip = false
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

    func updateShader(
        channel: VisualizerChannel,
        time: Double,
        bass: Double,
        mid: Double,
        high: Double,
        speed: Double
    ) {
        let params = channel.metalParams
        renderer.uniforms.time = Float(time)
        renderer.uniforms.bass = Float(bass)
        renderer.uniforms.mid = Float(mid)
        renderer.uniforms.high = Float(high)
        renderer.uniforms.hue = Float(params.hue)
        renderer.uniforms.grain = Float(params.grain)
        renderer.uniforms.chroma = Float(params.chroma)
        renderer.uniforms.speed = Float(speed)
        renderer.uniforms.satBoost = Float(params.saturation)
    }

    private var currentDuration: Double? {
        guard let item = player.currentItem else { return nil }
        let seconds = item.duration.seconds
        guard seconds.isFinite, seconds > 0 else { return nil }
        return seconds
    }

    private func load(url: URL) {
        teardownItemObservers()

        let item = AVPlayerItem(url: url)
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferMetalCompatibilityKey as String: true,
        ])
        item.add(output)
        videoOutput = output
        renderer.attachVideoOutput(output)

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
                self?.hasLoadedClip = true
                self?.installReverseBoundaryObserverIfNeeded()
                self?.applyPendingRate()
            }
        }

        player.replaceCurrentItem(with: item)
        player.isMuted = true
        applyPendingRate()
    }

    private func teardownItemObservers() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
        removeReverseBoundaryObserver()
        statusObserver?.invalidate()
        statusObserver = nil

        if let item = player.currentItem, let videoOutput {
            item.remove(videoOutput)
        }
        renderer.detachVideoOutput()
        videoOutput = nil
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

/// Metal-rendered visualizer clip — AVPlayer decodes off-screen, MTKView draws with VHS shader.
struct VisualizerVideoPlayerView: View {
    var channel: VisualizerChannel
    var time: Double
    var bass: Double
    var mid: Double
    var high: Double
    var speed: Double

    @ObservedObject var controller: VisualizerVideoController

    var body: some View {
        ZStack {
            VisualizerVideoMetalView(controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !controller.hasLoadedClip {
                Color.black
                Text("NO CLIPS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .background(Color.black)
        .onAppear {
            controller.updateShader(
                channel: channel,
                time: time,
                bass: bass,
                mid: mid,
                high: high,
                speed: speed
            )
            controller.resumeIfNeeded()
        }
        .onChange(of: channel) { _, newChannel in
            controller.updateShader(
                channel: newChannel,
                time: time,
                bass: bass,
                mid: mid,
                high: high,
                speed: speed
            )
        }
        .onChange(of: time) { _, newTime in
            controller.updateShader(
                channel: channel,
                time: newTime,
                bass: bass,
                mid: mid,
                high: high,
                speed: speed
            )
        }
        .onChange(of: bass) { _, _ in pushShaderUniforms() }
        .onChange(of: mid) { _, _ in pushShaderUniforms() }
        .onChange(of: high) { _, _ in pushShaderUniforms() }
        .onChange(of: speed) { _, _ in pushShaderUniforms() }
        .allowsHitTesting(false)
    }

    private func pushShaderUniforms() {
        controller.updateShader(
            channel: channel,
            time: time,
            bass: bass,
            mid: mid,
            high: high,
            speed: speed
        )
    }
}

private struct VisualizerVideoMetalView: UIViewRepresentable {
    @ObservedObject var controller: VisualizerVideoController

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        controller.renderer.configure(view: view)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) { }
}
