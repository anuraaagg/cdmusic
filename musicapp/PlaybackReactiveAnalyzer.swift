import Foundation

/// Smoothed pseudo-spectrum bands when real FFT is unavailable (`MPMusicPlayerController`).
@MainActor
final class PlaybackReactiveAnalyzer: ObservableObject {
    @Published private(set) var bass: Double = 0.08
    @Published private(set) var mid: Double = 0.06
    @Published private(set) var high: Double = 0.04

    private var phase: Double = 0
    private var seed: Double = 0.42

    func setSeed(from title: String) {
        seed = Double(abs(title.hashValue % 10_000)) / 10_000.0
    }

    func tick(isPlaying: Bool, speed: Double, dt: Double) {
        guard isPlaying else {
            bass = lerp(bass, 0.05, 0.05)
            mid = lerp(mid, 0.04, 0.05)
            high = lerp(high, 0.03, 0.06)
            return
        }

        phase += dt * (0.85 + speed * 0.35)
        let pulse = 0.5 + 0.5 * sin(phase * 2.4 + seed * 6.28)
        let shimmer = 0.5 + 0.5 * sin(phase * 5.1 + seed * 3.1)

        let targetBass = 0.18 + pulse * 0.42 * speed
        let targetMid = 0.12 + sin(phase * 1.7 + 1.2) * 0.22 * speed
        let targetHigh = 0.08 + shimmer * 0.18 * speed

        bass = lerp(bass, targetBass, 0.14)
        mid = lerp(mid, targetMid, 0.18)
        high = lerp(high, targetHigh, 0.22)
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }
}
