import SwiftUI

// MARK: - FigmaJamToolbar
//
// JAM top bar — Figma `305:3451` / `305:3384` (@402 × 64 pt row).
//
// `justify-between` row (fixed 64 pt height so side rail PNGs fit their slots):
//   Left-JAM (`305:3385`) | dial (`305:3388`) | status pills (`305:3390`) | arrow (`305:3395`)

struct FigmaJamToolbar: View {
    let statusText: String
    let counterText: String
    var scale: CGFloat = 1
    var isPlaying: Bool = false
    var onDialTap: () -> Void

    var body: some View {
        let m = FigmaTheme.JamToolbar.self
        let s = scale
        let rowH = m.rowHeight * s
        let clusterH = m.innerClusterHeight * s
        let railW = m.railWidth * s

        HStack(alignment: .center, spacing: 0) {
            FigmaJamLeftRail(scale: s)
                .frame(width: railW, height: clusterH)

            Spacer(minLength: m.clusterGapMin * s)

            FigmaJamDialButton(scale: s, isPlaying: isPlaying, action: onDialTap)

            FigmaJamStatusPills(
                statusText: statusText,
                counterText: counterText,
                scale: s
            )

            Spacer(minLength: m.clusterGapMin * s)

            FigmaJamRightRail(scale: s)
                .frame(width: railW, height: clusterH)
        }
        .frame(height: rowH)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Left JAM rail (`305:3385`)

struct FigmaJamLeftRail: View {
    var scale: CGFloat = 1

    var body: some View {
        FigmaJamRailDecoration(
            image: FigmaImage.jamLeftRail,
            scale: scale,
            alignment: .leading
        )
    }
}

// MARK: - Right arrow rail (`305:3395`)

struct FigmaJamRightRail: View {
    var scale: CGFloat = 1

    var body: some View {
        FigmaJamRailDecoration(
            image: FigmaImage.jamArrowRight,
            scale: scale,
            alignment: .trailing
        )
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

// MARK: - Rail PNG layout

private struct FigmaJamRailDecoration: View {
    let image: String
    var scale: CGFloat = 1
    var alignment: Alignment

    var body: some View {
        let m = FigmaTheme.JamToolbar.self
        let s = scale
        let slotW = m.railWidth * s
        let slotH = m.innerClusterHeight * s
        let imgW = slotW * m.railImageWidthBleed

        Color.clear
            .frame(width: slotW, height: slotH)
            .overlay(alignment: alignment) {
                Image(image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: imgW, height: slotH)
            }
            .clipped()
    }
}

// MARK: - Dial plate button (`305:3388`)

struct FigmaJamDialButton: View {
    var scale: CGFloat = 1
    var isPlaying: Bool = false
    let action: () -> Void

    @State private var tapSpin: Double = 0

    var body: some View {
        let m = FigmaTheme.JamToolbar.self
        let s = scale
        let pad = m.dialPadding * s
        let boxR = m.dialBoxCorner * s
        let dialSz = m.dialSize * s
        let boxSide = dialSz + pad * 2

        Button {
            tapSpin += 120
            action()
        } label: {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { timeline in
                let playSpin = isPlaying
                    ? timeline.date.timeIntervalSinceReferenceDate * 48.0
                    : 0
                FigmaJamDial(size: dialSz, spinDegrees: playSpin + tapSpin)
                    .animation(.spring(response: 0.42, dampingFraction: 0.72), value: tapSpin)
            }
            .padding(pad)
            .frame(width: boxSide, height: boxSide)
            .background(FigmaTheme.jamPillFill)
            .clipShape(RoundedRectangle(cornerRadius: boxR, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open library")
        .accessibilityIdentifier("library.open")
    }
}

#Preview("JAM toolbar — 305:3384") {
    VStack(spacing: 8) {
        FigmaJamToolbar(
            statusText: "not playing",
            counterText: "1-68",
            onDialTap: {}
        )
    }
    .padding(.top, 12)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}
