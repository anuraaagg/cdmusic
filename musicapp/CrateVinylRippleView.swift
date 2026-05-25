import SwiftUI

// MARK: - Crate vinyl tap ripple (Metal distortion + wavefront highlight)

private struct RippleShockwave: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let birth: TimeInterval
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
    private let rippleSpeed: CGFloat = 1400
    /// Wavefront ring peak opacity (was 0.02 — effectively invisible on cream crate).
    private let highlightAlpha: CGFloat = 0.30

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            RippleVinylContent(
                sleeveIndex: sleeveIndex,
                discArtwork: discArtwork,
                labelColor: labelColor,
                rotation: rotation,
                cellSize: cellSize,
                scrollVelocity: scrollVelocity,
                shockwaves: shockwaves,
                now: timeline.date.timeIntervalSinceReferenceDate,
                rippleSpeed: rippleSpeed,
                highlightAlpha: highlightAlpha
            )
        }
        .crateVinylParallax(norm: parallaxNorm)
        .contentShape(Circle())
        .onTapGesture(coordinateSpace: .local) { point in
            triggerRipple(at: point)
            onTap()
        }
    }

    private func triggerRipple(at point: CGPoint) {
        shockwaves.append(RippleShockwave(origin: point, birth: Date.timeIntervalSinceReferenceDate))
        if shockwaves.count > maxRipples {
            shockwaves.removeFirst(shockwaves.count - maxRipples)
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
    let rippleSpeed: CGFloat
    let highlightAlpha: CGFloat

    private let rippleDecay: CGFloat = 5.5

    private var activeWaves: [RippleShockwave] {
        shockwaves.filter { age(of: $0) < maxRippleLifetime }
    }

    private var maxRippleLifetime: TimeInterval {
        Double(cellSize * 1.5 / rippleSpeed) + Double(1.0 / rippleDecay) + 0.35
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
            let w0 = waveSlot(index: 0)
            let w1 = waveSlot(index: 1)
            let w2 = waveSlot(index: 2)
            let w3 = waveSlot(index: 3)
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
                    maxSampleOffset: CGSize(width: 28, height: 28)
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

    private func waveSlot(index: Int) -> (Float, Float, Float, Float) {
        guard activeWaves.indices.contains(index) else {
            return (0, 0, -1, 0)
        }
        let wave = activeWaves[index]
        let t = Float(age(of: wave))
        return (Float(wave.origin.x), Float(wave.origin.y), t, 1)
    }

    private var rippleHighlights: some View {
        Canvas { context, size in
            for wave in activeWaves {
                let age = age(of: wave)
                let distance = age * rippleSpeed
                let maxEdge = max(size.width, size.height) * 0.5
                let progress = min(1, distance / maxEdge)
                let radius = max(1, distance)
                let opacity = highlightAlpha * (1 - min(1, progress / 0.50))

                guard opacity > 0.01 else { continue }

                let ring = Path(ellipseIn: CGRect(
                    x: wave.origin.x - radius,
                    y: wave.origin.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))

                context.stroke(
                    ring,
                    with: .color(FigmaTheme.orangeAccent.opacity(opacity)),
                    lineWidth: 2
                )
            }
        }
        .allowsHitTesting(false)
    }
}
