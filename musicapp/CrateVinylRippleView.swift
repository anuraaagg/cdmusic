import SwiftUI

// MARK: - Crate vinyl tap ripple (Metal distortion + wavefront highlight)

private struct RippleShockwave: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let birth: TimeInterval
}

/// Pure ripple slot math — safe to call from `visualEffect` (nonisolated render context).
private enum RippleWaveMath {
    nonisolated static func waveSlot(
        index: Int,
        shockwaves: [RippleShockwave],
        now: TimeInterval,
        duration: TimeInterval
    ) -> (Float, Float, Float, Float) {
        let active = shockwaves.filter { max(0, now - $0.birth) < duration }
        guard active.indices.contains(index) else {
            return (0, 0, -1, 0)
        }
        let wave = active[index]
        let t = Float(max(0, now - wave.birth))
        return (Float(wave.origin.x), Float(wave.origin.y), t, 1)
    }
}

/// Carousel vinyl cell with tap ripple, scroll barrel warp, fling blur, and parallax depth.
struct CrateVinylRippleView: View {
    let sleeveIndex: Int
    var discArtwork: UIImage?
    var labelColor: UIColor = UIColor(T3Color.labelDark.opacity(0.35))
    var rotation: Double = 0
    var cellSize: CGFloat = 200
    var parallaxNorm: CGFloat = 0
    var scrollVelocity: CGFloat = 0
    var onTap: () -> Void = {}

    @State private var shockwaves: [RippleShockwave] = []

    private let maxRipples = 4
    /// Slow radial expansion + long ease-out keeps tap feedback soft, not punchy.
    private let rippleDuration: TimeInterval = 1.45
    /// Must stay in rough sync with Metal `kSpeed`.
    private let rippleSpeed: CGFloat = 440

    var body: some View {
        Group {
            if shockwaves.isEmpty {
                vinylBody(now: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    vinylBody(now: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .crateVinylParallax(norm: parallaxNorm)
        .contentShape(Circle())
        .onTapGesture(coordinateSpace: .local) { point in
            triggerRipple(at: point)
            onTap()
        }
    }

    @ViewBuilder
    private func vinylBody(now: TimeInterval) -> some View {
        RippleVinylContent(
            sleeveIndex: sleeveIndex,
            discArtwork: discArtwork,
            labelColor: labelColor,
            rotation: rotation,
            cellSize: cellSize,
            scrollVelocity: scrollVelocity,
            shockwaves: shockwaves,
            now: now,
            rippleDuration: rippleDuration,
            rippleSpeed: rippleSpeed
        )
    }

    private func triggerRipple(at point: CGPoint) {
        let wave = RippleShockwave(origin: point, birth: Date.timeIntervalSinceReferenceDate)
        shockwaves.append(wave)
        if shockwaves.count > maxRipples {
            shockwaves.removeFirst(shockwaves.count - maxRipples)
        }

        let waveID = wave.id
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleDuration) {
            shockwaves.removeAll { $0.id == waveID }
        }
    }
}

private struct RippleVinylContent: View {
    let sleeveIndex: Int
    var discArtwork: UIImage?
    var labelColor: UIColor
    var rotation: Double
    var cellSize: CGFloat
    let scrollVelocity: CGFloat
    let shockwaves: [RippleShockwave]
    let now: TimeInterval
    let rippleDuration: TimeInterval
    let rippleSpeed: CGFloat

    private var activeWaves: [RippleShockwave] {
        shockwaves.filter { age(of: $0) < rippleDuration }
    }

    var body: some View {
        FigmaVinylView(
            sleeveIndex: sleeveIndex,
            discArtwork: discArtwork,
            labelColor: labelColor,
            rotation: rotation,
            cellSize: cellSize
        )
        .visualEffect { content, proxy in
            let w0 = RippleWaveMath.waveSlot(index: 0, shockwaves: shockwaves, now: now, duration: rippleDuration)
            let w1 = RippleWaveMath.waveSlot(index: 1, shockwaves: shockwaves, now: now, duration: rippleDuration)
            let w2 = RippleWaveMath.waveSlot(index: 2, shockwaves: shockwaves, now: now, duration: rippleDuration)
            let w3 = RippleWaveMath.waveSlot(index: 3, shockwaves: shockwaves, now: now, duration: rippleDuration)
            let size = proxy.size

            return content
                .distortionEffect(
                    ShaderLibrary.crateVinylDistortion(
                        .float4(w0.0, w0.1, w0.2, w0.3),
                        .float4(w1.0, w1.1, w1.2, w1.3),
                        .float4(w2.0, w2.1, w2.2, w2.3),
                        .float4(w3.0, w3.1, w3.2, w3.3),
                        .float(Float(size.width)),
                        .float(Float(size.height)),
                        .float(Float(scrollVelocity))
                    ),
                    maxSampleOffset: CGSize(width: 12, height: 12)
                )
                .layerEffect(
                    ShaderLibrary.crateMotionBlur(
                        .float(Float(size.width)),
                        .float(Float(size.height)),
                        .float(Float(scrollVelocity))
                    ),
                    maxSampleOffset: CGSize(width: 24, height: 2)
                )
        }
        .overlay {
            rippleHighlights
        }
    }

    private func age(of wave: RippleShockwave) -> TimeInterval {
        max(0, now - wave.birth)
    }

    private var rippleHighlights: some View {
        Canvas { context, size in
            for wave in activeWaves {
                let age = age(of: wave)
                let life = age / rippleDuration
                guard life < 1 else { continue }

                let fade = 1 - life
                let distance = age * rippleSpeed
                let radius = max(2, distance)
                /// Ease-out opacity so peak is mellow, tail is long (matches slow swell).
                let ringOpacity = 0.17 * fade * fade * fade * fade

                // Soft expanding halo ring (minimal contrast).
                let ring = Path(ellipseIn: CGRect(
                    x: wave.origin.x - radius,
                    y: wave.origin.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.stroke(
                    ring,
                    with: .color(FigmaTheme.orangeAccent.opacity(ringOpacity)),
                    lineWidth: 1.05
                )

                /// Tiny center blush — fades before the swell dominates.
                let pulseRadius = cellSize * 0.048 * (1 + life * 0.9)
                let pulseOpacity = 0.07 * max(0, 1 - life / 0.4)
                if pulseOpacity > 0.01 {
                    let pulse = Path(ellipseIn: CGRect(
                        x: wave.origin.x - pulseRadius,
                        y: wave.origin.y - pulseRadius,
                        width: pulseRadius * 2,
                        height: pulseRadius * 2
                    ))
                    context.fill(pulse, with: .color(FigmaTheme.orangeAccent.opacity(pulseOpacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
