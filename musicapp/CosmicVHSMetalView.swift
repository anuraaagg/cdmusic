import SwiftUI

/// Metal cosmic VHS pass — wraps `cosmicVHS` stitchable shader.
struct CosmicVHSMetalView: View {
    var channel: VisualizerChannel
    var time: Double
    var bass: Double
    var mid: Double
    var high: Double
    var spinAngle: Double
    var speed: Double = 1
    var opacity: Double = 1
    var saturationBoost: Double = 1

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.black)
                .visualEffect { content, proxy in
                    content.colorEffect(cosmicShader(size: proxy.size))
                }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }

    private func cosmicShader(size: CGSize) -> Shader {
        let p = channel.metalParams
        return ShaderLibrary.cosmicVHS(
            .float(Float(size.width)),
            .float(Float(size.height)),
            .float(Float(time)),
            .float(Float(bass)),
            .float(Float(mid)),
            .float(Float(high)),
            .float(Float(p.hue)),
            .float(Float(p.bloom * speed)),
            .float(Float(p.grain)),
            .float(Float(p.chroma)),
            .float(Float(spinAngle)),
            .float(Float(saturationBoost))
        )
    }
}

extension VisualizerChannel {
    var metalParams: (hue: Double, bloom: Double, grain: Double, chroma: Double) {
        switch self {
        case .cosmicVHS:   return (0.88, 1.0, 0.42, 0.018)
        case .nebulaDream: return (0.62, 0.75, 0.28, 0.012)
        case .crtBloom:    return (0.35, 1.15, 0.35, 0.032)
        case .deepSpace:   return (0.72, 0.55, 0.48, 0.010)
        }
    }
}
