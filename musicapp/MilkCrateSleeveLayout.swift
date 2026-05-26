import simd

/// Pure layout math for vertically stacked jackets in the RealityKit crate.
enum MilkCrateSleeveLayout {
    static let zFrontBaseline: Float = 0.1
    static let zSpacing: Float = -0.02
    static let xStaggerPerRecord: Float = 0.0036
    static let yStanding: Float = 0.04
    static let yawHighlightPerDepth: Float = 0.04
    /// Front-of-stack record scale; records behind taper slightly for depth cue.
    static let scaleFront: Float = 1.02
    static let scaleBack: Float = 0.93

    static func normalizedDepth(stackIndex: Int, frontIndex: Int) -> Float {
        Float(stackIndex - frontIndex)
    }

    /// World position before pop-out correction.
    static func position(stackIndex: Int, frontIndex: Int, count _: Int) -> SIMD3<Float> {
        let d = normalizedDepth(stackIndex: stackIndex, frontIndex: frontIndex)
        let z = zFrontBaseline + zSpacing * d
        let x = xStaggerPerRecord * Float(stackIndex)
        return SIMD3<Float>(x, yStanding, z)
    }

    /// Local forward (toward viewer) adjustment for sharing / latch pop.
    static func popOffsetZ(popOutProgress: Float) -> Float {
        popOutProgress * 0.042
    }

    static func sleeveScale(depthFromFrontHighlight: Float) -> Float {
        let t = min(max(depthFromFrontHighlight, 0), 6)
        return scaleFront + Float(t) / 6 * (scaleBack - scaleFront)
    }

    /// Rim spawn height for a new sleeve (above final slot).
    static func insertSpawnYOffset() -> Float { 0.22 }
}
