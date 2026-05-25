import AVFoundation

// MARK: - Drawer mechanical SFX (no bundled assets)

/// Soft slide on open + latch click on close; gated by `MusicPlayerViewModel.isSoundEnabled`.
@MainActor
final class DrawerMechanicalSound {
    static let shared = DrawerMechanicalSound()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isConfigured = false

    private init() {}

    func playSlideOpen() {
        play(buffer: makeSlideBuffer())
    }

    func playLatchClose() {
        play(buffer: makeLatchBuffer())
    }

    private func play(buffer: AVAudioPCMBuffer) {
        configureIfNeeded()
        guard isConfigured else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.42
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try engine.start()
            isConfigured = true
        } catch {
            isConfigured = false
        }
    }

    /// Filtered noise ramp — drawer sliding on rails.
    private func makeSlideBuffer() -> AVAudioPCMBuffer {
        let sampleRate = 44_100.0
        let duration = 0.14
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return buffer }

        var rng: UInt64 = 0xC0FFEE
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envIn = min(1, t / 0.018)
            let envOut = min(1, (duration - t) / 0.04)
            let env = Float(envIn * envOut)
            rng = rng &* 6364136223846793005 &+ 1
            let noise = Float(Int64(bitPattern: rng) % 10_000) / 10_000 - 0.5
            let tone = sin(2 * .pi * 180 * t) * 0.12
            samples[i] = (noise * 0.55 + Float(tone)) * env * 0.38
        }
        return buffer
    }

    /// Short metallic latch — close detent.
    private func makeLatchBuffer() -> AVAudioPCMBuffer {
        let sampleRate = 44_100.0
        let duration = 0.055
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env = Float(exp(-t * 95))
            let click = sin(2 * .pi * 2_800 * t) * 0.55 + sin(2 * .pi * 5_200 * t) * 0.22
            let thud = sin(2 * .pi * 420 * t) * 0.35 * exp(-t * 40)
            samples[i] = Float(click + thud) * env * 0.52
        }
        return buffer
    }
}
