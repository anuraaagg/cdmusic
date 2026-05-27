import Foundation

/// Card-flip settle for draggable CD → crate opening.
enum CrateDropAnimationSpec {
    static let flipSpringStiffness: CGFloat = 155
    static let flipSpringDamping: CGFloat = 20

    static let windUpDuration: TimeInterval = 0.08
    static let windUpScale: CGFloat = 1.03
    static let windUpTiltX: Double = 6

    /// Stay readable — tuck into opening without shrinking to a thumbnail.
    static let landedScale: CGFloat = 0.84
    static let landedTiltX: Double = -38
    static let landedTiltY: Double = 0

    static let finishSettlingDelaySeconds: TimeInterval = 0.82
}
