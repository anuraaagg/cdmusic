import SwiftUI

/// INDmoney-style card flip: tilt back on X, optional Y, perspective depth.
struct CrateDiscCardFlipModifier: ViewModifier {
    var tiltX: Double
    var tiltY: Double
    var perspective: CGFloat = 0.62

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(tiltX), axis: (x: 1, y: 0, z: 0), perspective: perspective)
            .rotation3DEffect(.degrees(tiltY), axis: (x: 0, y: 1, z: 0), perspective: perspective * 0.85)
    }
}

extension View {
    func crateDiscCardFlip(tiltX: Double, tiltY: Double = 0, perspective: CGFloat = 0.62) -> some View {
        modifier(CrateDiscCardFlipModifier(tiltX: tiltX, tiltY: tiltY, perspective: perspective))
    }
}
