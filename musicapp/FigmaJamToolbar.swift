import SwiftUI

// MARK: - FigmaJamToolbar
//
// JAM top bar — Figma `305:3451` / `465:10794` (@402 × 64 pt row).

struct FigmaJamToolbar: View {
    let statusText: String
    let counterText: String
    var scale: CGFloat = 1
    var isPlaying: Bool = false
    var showsBackArrow: Bool = false
    var onDialTap: () -> Void
    var onArrowTap: (() -> Void)?

    var body: some View {
        let m = FigmaTheme.JamToolbar.self
        let s = scale
        let rowH = m.rowHeight * s
        let clusterH = m.innerClusterHeight * s
        let railW = m.railWidth * s

        HStack(alignment: .center, spacing: 0) {
            FigmaJamLeftRail(scale: s)
                .frame(width: railW, height: clusterH)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Spacer(minLength: m.clusterGapMin * s)

            FigmaJamDialButton(scale: s, isPlaying: isPlaying, action: onDialTap)
                .frame(width: clusterH, height: clusterH)

            FigmaJamStatusPills(
                statusText: statusText,
                counterText: counterText,
                scale: s
            )
            .frame(height: clusterH)

            Spacer(minLength: m.clusterGapMin * s)

            FigmaJamBackRailButton(
                scale: s,
                pointsBack: showsBackArrow,
                onTap: onArrowTap
            )
            .frame(width: railW, height: clusterH)
        }
        .frame(height: rowH, alignment: .center)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Left JAM rail (`305:3385`) — PNG only, not tappable

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

// MARK: - Right back rail (`465:10794`) — PNG shell + coded arrow

struct FigmaJamBackRailButton: View {
    var scale: CGFloat = 1
    /// `true` → arrow points left (return to controls).
    var pointsBack: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        let m = FigmaTheme.JamToolbar.self
        let s = scale
        let slotW = m.railWidth * s
        let slotH = m.innerClusterHeight * s
        let imgW = slotW * m.railImageWidthBleed

        Button {
            onTap?()
        } label: {
            Color.clear
                .frame(width: slotW, height: slotH)
                .overlay(alignment: .trailing) {
                    Image(FigmaImage.jamBackRail)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .frame(width: imgW, height: slotH)
                }
                .overlay {
                    FigmaJamRailArrow()
                        .stroke(
                            Color.black.opacity(0.88),
                            style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 10 * s, height: 8 * s)
                        .rotationEffect(.degrees(pointsBack ? 0 : 180))
                        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: pointsBack)
                }
                .clipped()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pointsBack ? "Back to controls" : "Open visualizer")
        .accessibilityIdentifier(pointsBack ? "visualizer.back" : "visualizer.open")
    }
}

/// Left-pointing chevron — only this layer rotates inside the static PNG rail.
struct FigmaJamRailArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY))
        return path
    }
}

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

#Preview("JAM toolbar — control page") {
    FigmaJamToolbar(
        statusText: "not playing",
        counterText: "1-68",
        showsBackArrow: false,
        onDialTap: {}
    )
    .padding(.top, 12)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}

#Preview("JAM toolbar — visual page") {
    FigmaJamToolbar(
        statusText: "hip-hop",
        counterText: "1-68",
        showsBackArrow: true,
        onDialTap: {}
    )
    .padding(.top, 12)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}
