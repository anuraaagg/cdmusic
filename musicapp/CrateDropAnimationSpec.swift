import Foundation

/// Single timeline for SwiftUI jewel → RealityKit sleeve hand-off (`397:3639`).
enum CrateDropAnimationSpec {
    /// 2D disc springs into opening.
    static let springToOpeningResponse: CGFloat = 0.45

    /// When the draggable disc fades out — hand off to the 3D insert.
    static let crossRimDelaySeconds: CGFloat = 0.35

    /// Full settle before phase becomes `.success`.
    static let finishSettlingDelaySeconds: CGFloat = 0.72

    /// Mid-settle jewel scale / tilt nudge (`FigmaCrateDropSheet`).
    static let jewelScalePeak: CGFloat = 0.62
    static let jewelScaleRest: CGFloat = 0.7
    static let jewelTweakDelaySeconds: CGFloat = 0.58
    static let jewelTiltPeakDegrees: Double = -28
    static let jewelTiltRestDegrees: Double = -8

    /// Sleeve drops from rim into stack position.
    static let sleeveLandingDurationSeconds: TimeInterval = 0.38
}
