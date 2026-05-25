import SwiftUI

// MARK: - FigmaVolControl3375622
//
// Native SwiftUI volume strip — Figma node `337:5622` (@131.941 pt tall).
//
//   Label cluster `305:2700`  — orange ⌐ brackets + rotated VOL
//   Slider `337:5627`         — dark capsule rail + centre tick + raised knob

private enum VolLabel3052700 {
    /// Figma `305:2700` — orange bracket + rotated VOL label cluster.
    static let nativeHeight: CGFloat = 120
    static let clusterWidth: CGFloat = 28

    static let chevronWidth: CGFloat = 18.48
    static let chevronHeight: CGFloat = 33.818
    static let chevronLeading: CGFloat = 9.52

    static let volFontSize: CGFloat = 16.364
    static let volTop: CGFloat = 42.62
    static let volBlockHeight: CGFloat = 33
    static let volCenterX: CGFloat = 10.27

    static func s(_ height: CGFloat, _ design: CGFloat) -> CGFloat {
        height * design / nativeHeight
    }
}

private enum Vol3375622 {
    static let nativeHeight: CGFloat = 131.941
    static let sliderWidth: CGFloat = 45.078

    /// Capsule rail from exported slider SVG (viewBox 50.19 × 120).
    static let trackCapsuleWidth: CGFloat = 8.157
    static let trackCapsuleCenterX: CGFloat = 22.120
    static let trackFill = Color(red: 34 / 255, green: 23 / 255, blue: 23 / 255) // #221717

    static let tickColor = Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255) // #141414
    static let tickWidth: CGFloat = 40.0

    static let knobRadiusX: CGFloat = 13.490
    static let knobRadiusY: CGFloat = 13.063

    static let creamLight = Color(red: 228 / 255, green: 222 / 255, blue: 219 / 255)
    static let creamDark  = Color(red: 230 / 255, green: 225 / 255, blue: 223 / 255)
    static let rimTint    = Color(red: 209 / 255, green: 204 / 255, blue: 200 / 255)

    static func s(_ height: CGFloat, _ design: CGFloat) -> CGFloat {
        height * design / nativeHeight
    }
}

struct FigmaVolControl3375622: View {
    @ObservedObject var vm: MusicPlayerViewModel
    var height: CGFloat
    var scale: CGFloat = 1

    @State private var volumeDragBuckets = -1

    var body: some View {
        HStack(spacing: 0) {
            labelCluster
            slider
        }
        .frame(height: height)
    }

    // MARK: - Label cluster (`305:2700`)

    private var labelCluster: some View {
        let h = height
        let chevW = VolLabel3052700.s(h, VolLabel3052700.chevronWidth)
        let chevH = VolLabel3052700.s(h, VolLabel3052700.chevronHeight)
        let chevX = VolLabel3052700.s(h, VolLabel3052700.chevronLeading)
        let labelW = VolLabel3052700.s(h, VolLabel3052700.clusterWidth)
        let volCenterY = VolLabel3052700.s(
            h,
            VolLabel3052700.volTop + VolLabel3052700.volBlockHeight / 2
        )
        let stroke = max(1.0, 1.05 * scale)

        return ZStack(alignment: .topLeading) {
            FigmaVolChevron()
                .stroke(FigmaTheme.orangeAccent, lineWidth: stroke)
                .frame(width: chevW, height: chevH)
                .offset(x: chevX, y: 0)

            FigmaVolChevron()
                .stroke(FigmaTheme.orangeAccent, lineWidth: stroke)
                .frame(width: chevW, height: chevH)
                .scaleEffect(x: 1, y: -1)
                .offset(x: chevX, y: h - chevH)

            Text("VOL")
                .font(FigmaFont.vol(VolLabel3052700.s(h, VolLabel3052700.volFontSize)))
                .foregroundStyle(FigmaTheme.orangeAccent)
                .rotationEffect(.degrees(-90))
                .fixedSize()
                .position(
                    x: VolLabel3052700.s(h, VolLabel3052700.volCenterX),
                    y: volCenterY
                )
        }
        .frame(width: labelW, height: h)
        .allowsHitTesting(false)
    }

    // MARK: - Slider (`337:5627`)

    private var slider: some View {
        let h = height
        let sliderW = Vol3375622.s(h, Vol3375622.sliderWidth)
        let railW = Vol3375622.s(h, Vol3375622.trackCapsuleWidth)
        let railX = Vol3375622.s(h, Vol3375622.trackCapsuleCenterX)
        let knobW = Vol3375622.s(h, Vol3375622.knobRadiusX * 2)
        let knobH = Vol3375622.s(h, Vol3375622.knobRadiusY * 2)
        let tickW = Vol3375622.s(h, Vol3375622.tickWidth)
        let tickH = max(0.5, Vol3375622.s(h, 0.608))

        return ZStack(alignment: .topLeading) {
            // Centre tick — spans wider than the rail.
            Rectangle()
                .fill(Vol3375622.tickColor)
                .frame(width: tickW, height: tickH)
                .position(x: railX, y: h * 0.5)

            // Dark capsule rail.
            Capsule()
                .fill(Vol3375622.trackFill)
                .frame(width: railW, height: h)
                .position(x: railX, y: h * 0.5)

            // Raised knob — moves with volume.
            volKnob(width: knobW, height: knobH)
                .position(x: railX, y: knobY(in: h, knobH: knobH))

            // Touch target.
            Rectangle()
                .fill(Color.black.opacity(0.001))
                .frame(width: sliderW * 1.4, height: h + Vol3375622.s(h, 16))
                .position(x: sliderW * 0.5, y: h * 0.5)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { touchVolume(atY: $0.location.y, h: h, isFirst: volumeDragBuckets < 0) }
                        .onEnded { _ in
                            volumeDragBuckets = -1
                            vm.selectionChanged()
                            vm.flashVolumeHUD()
                        }
                )
        }
        .frame(width: sliderW, height: h)
    }

    private func volKnob(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 15 / 255, green: 14 / 255, blue: 14 / 255).opacity(0.22))
                .frame(width: w * 0.9, height: h * 0.35)
                .blur(radius: w * 0.06)
                .offset(y: h * 0.18)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Vol3375622.creamLight, Vol3375622.creamDark],
                        startPoint: UnitPoint(x: 0.12, y: 0.10),
                        endPoint: UnitPoint(x: 0.88, y: 0.92)
                    )
                )
                .overlay(
                    Ellipse()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Vol3375622.rimTint, Vol3375622.rimTint.opacity(0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(0.5, w * 0.025)
                        )
                )
                .frame(width: w, height: h)
                .shadow(color: .black.opacity(0.18), radius: w * 0.08, x: w * 0.04, y: w * 0.05)
                .shadow(color: .black.opacity(0.35), radius: w * 0.14, x: w * 0.06, y: w * 0.08)
        }
    }

    private func knobY(in h: CGFloat, knobH: CGFloat) -> CGFloat {
        let travel = max(0, h - knobH)
        let frac = CGFloat(1 - clamp01(Double(vm.volume)))
        return knobH * 0.5 + travel * frac
    }

    private func touchVolume(atY y: CGFloat, h: CGFloat, isFirst: Bool) {
        let frac = 1 - Double(clampCGFloat(y / max(h, 1)))
        VolumeManager.shared.setVolume(Float(frac))
        vm.flashVolumeHUD()
        if isFirst {
            vm.impact(.rigid)
            volumeDragBuckets = Int(frac * 24)
        }
        let b = Int(frac * 24)
        if b != volumeDragBuckets {
            volumeDragBuckets = b
            vm.selectionChanged()
        }
    }

    private func clampCGFloat(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }
    private func clamp01(_ x: Double) -> Double { min(max(x, 0), 1) }
}

// MARK: - Preview

#Preview("VOL — 337:5622") {
    FigmaVolControl3375622(vm: MusicPlayerViewModel(), height: 131.941)
        .padding(40)
        .background(FigmaTheme.panelGrey)
}
