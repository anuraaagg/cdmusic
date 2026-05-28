import SwiftUI

// MARK: - ArcadeDisplayIdleView
//
// Layered attract-mode LCD (`479 × 195` ref) with subtle default motion.
// Used inside `FigmaArcadeDisplayView` when the cosmic visualizer is off.

struct ArcadeDisplayIdleView: View {
    let width: CGFloat
    let height: CGFloat
    var selectedChannel: VisualizerChannel = .cosmicVHS
    var bass: Double = 0.08
    var mid: Double = 0.06
    var high: Double = 0.06
    var onGenreTap: ((VisualizerChannel) -> Void)?

    @State private var phase: Double = 0
    @State private var spinAngle: Double = 0
    @State private var insertCoinLit = true

    private static let designW: CGFloat = 479
    private static let designH: CGFloat = 195

    private var sx: CGFloat { width / Self.designW }
    private var sy: CGFloat { height / Self.designH }

    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let blinkTimer = Timer.publish(every: 1.1, on: .main, in: .common).autoconnect()

    private var displayGenres: [VisualizerChannel] {
        VisualizerChannel.allCases.filter { $0 != .deepSpace }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            lcdBackground
            cabinetLayers
            genreLabels
            clockReadout
            insertCoinLabel
            abButtons
            genreTapTargets
        }
        .frame(width: width, height: height)
        .clipped()
        .onReceive(tick) { _ in
            phase += 0.035
            spinAngle = (spinAngle + 0.12).truncatingRemainder(dividingBy: 360)
        }
        .onReceive(blinkTimer) { _ in
            insertCoinLit.toggle()
        }
    }

    // MARK: - Shell

    private var lcdBackground: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 1 / 255, green: 1 / 255, blue: 1 / 255)
            RoundedRectangle(cornerRadius: 4 * sx, style: .continuous)
                .fill(Color(red: 191 / 255, green: 196 / 255, blue: 199 / 255))
                .frame(width: width - 16 * sx, height: height - 24 * sy)
                .offset(x: 8 * sx, y: 15 * sy)
        }
    }

    // MARK: - Cabinet art

    private var cabinetLayers: some View {
        ZStack(alignment: .topLeading) {
            imageLayer(ArcadeImage.frameLeft, w: 159, h: 129, x: 156, y: 18)
            imageLayer(ArcadeImage.frameLeftTrim, w: 22, h: 129, x: 156, y: 18)
                .opacity(0.82 + sin(phase * 1.4) * 0.12)
            imageLayer(ArcadeImage.frameRightTrim, w: 22, h: 129, x: 300, y: 18)
                .opacity(0.82 + cos(phase * 1.3) * 0.12)

            imageLayer(ArcadeImage.screenBezel, w: 152, h: 21, x: 163, y: 65)
                .offset(y: sin(phase * 0.85) * 1.0 * sy)

            Text("ARCADE")
                .font(.system(size: 22 * sx, weight: .regular))
                .foregroundStyle(Color(red: 0.74, green: 0.76, blue: 0.77))
                .frame(width: 140 * sx)
                .offset(x: 169 * sx, y: 32 * sy)
                .opacity(0.92 + sin(phase * 0.9) * 0.06)

            imageLayer(ArcadeImage.iconFrame, w: 26, h: 25, x: 96, y: 25)
                .rotationEffect(.degrees(sin(phase * 0.7) * 2.5), anchor: .bottom)

            equalizerLayer

            imageLayer(ArcadeImage.knobLeft, w: 34, h: 34, x: 135, y: 23)
                .rotationEffect(.degrees(spinAngle * 0.25))
            imageLayer(ArcadeImage.knobRight, w: 34, h: 34, x: 309, y: 23)
                .rotationEffect(.degrees(-spinAngle * 0.2))

            imageLayer(ArcadeImage.speakerLeft, w: 18, h: 13, x: 186, y: 69)
                .opacity(0.62 + sin(phase * 2.1) * 0.18)
            imageLayer(ArcadeImage.speakerRight, w: 18, h: 13, x: 274, y: 69)
                .opacity(0.62 + cos(phase * 2.0) * 0.18)

            imageLayer(ArcadeImage.vinylGrid, w: 44, h: 44, x: 217, y: 94)
                .rotationEffect(.degrees(spinAngle * 0.35))
                .offset(y: sin(phase * 0.85) * 1.4 * sy)

            levelMeterOverlay

            imageLayer(ArcadeImage.controlsLeft, w: 46, h: 28, x: 21, y: 86)
                .offset(y: sin(phase * 1.6) * 1.2 * sy)

            imageLayer(ArcadeImage.handle, w: 166, h: 26, x: 156, y: 151)
                .offset(y: sin(phase * 1.1) * 0.8 * sy)

            imageLayer(ArcadeImage.btnStar, w: 22, h: 22, x: 16, y: 151)
                .opacity(0.75 + sin(phase * 2.4) * 0.2)
                .scaleEffect(0.96 + sin(phase * 2.4) * 0.04)

            HStack(spacing: 4 * sx) {
                ForEach(0..<3, id: \.self) { i in
                    Image(ArcadeImage.btnHeart)
                        .resizable()
                        .frame(width: 19 * sx, height: 22 * sy)
                        .opacity(i == 1 ? 0.85 + sin(phase * 1.8) * 0.12 : 0.7)
                }
            }
            .offset(x: 41 * sx, y: 151 * sy)
        }
    }

    private var equalizerLayer: some View {
        let eqScale = 0.90 + sin(phase) * 0.05 + bass * 0.06
        return Image(ArcadeImage.equalizer)
            .resizable()
            .interpolation(.none)
            .frame(width: 30 * sx, height: 78 * sy)
            .scaleEffect(x: 1, y: eqScale, anchor: .bottom)
            .offset(x: 94 * sx, y: 89 * sy)
    }

    /// Right-column segmented meter — gentle idle jitter + audio bands.
    private var levelMeterOverlay: some View {
        let originX: CGFloat = 368
        let originY: CGFloat = 88
        let colW: CGFloat = 5
        let colGap: CGFloat = 4
        let maxH: CGFloat = 52
        let bands = [bass, mid, high, (bass + mid) * 0.5]

        return HStack(alignment: .bottom, spacing: colGap * sx) {
            ForEach(Array(bands.enumerated()), id: \.offset) { index, level in
                let wobble = sin(phase * 1.7 + Double(index) * 0.9) * 0.06
                let h = maxH * (0.35 + wobble + level * 0.45)
                RoundedRectangle(cornerRadius: 0.5 * sx, style: .continuous)
                    .fill(Color.black.opacity(0.88))
                    .frame(width: colW * sx, height: h * sy)
            }
        }
        .offset(x: originX * sx, y: originY * sy)
        .allowsHitTesting(false)
    }

    // MARK: - Labels & controls

    private var genreLabels: some View {
        ForEach(displayGenres) { channel in
            let active = channel == selectedChannel
            Text(channel.displayLabel)
                .font(.system(size: 16 * sx, weight: active ? .bold : .regular))
                .foregroundStyle(active ? Color.black : Color(red: 0.69, green: 0.71, blue: 0.72))
                .scaleEffect(active ? 1.02 : 1, anchor: .leading)
                .offset(x: 16 * sx, y: genreY(channel) * sy)
                .animation(.easeInOut(duration: 0.2), value: selectedChannel)
        }
    }

    private var clockReadout: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let time = context.date
            let hour = Calendar.current.component(.hour, from: time) % 12
            let minute = Calendar.current.component(.minute, from: time)
            let isAM = Calendar.current.component(.hour, from: time) < 12
            let text = String(format: "%02d:%02d", hour == 0 ? 12 : hour, minute)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 1 * sx) {
                    ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                        if ch == ":" {
                            Text(":")
                                .font(.system(size: 22 * sx, weight: .light, design: .monospaced))
                                .foregroundStyle(Color.black.opacity(0.95))
                        } else {
                            Image(digitImage(for: ch))
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 15.4 * sx, height: 29 * sy)
                        }
                    }
                }
                .offset(x: 358 * sx, y: 23 * sy)
                .opacity(0.94 + sin(phase * 0.5) * 0.04)

                Text("AM")
                    .font(.system(size: 10 * sx))
                    .foregroundStyle(isAM ? Color.black.opacity(0.98) : Color(red: 0.75, green: 0.77, blue: 0.78))
                    .offset(x: 439 * sx, y: 25 * sy)
                Text("PM")
                    .font(.system(size: 10 * sx))
                    .foregroundStyle(isAM ? Color(red: 0.75, green: 0.77, blue: 0.78) : Color.black.opacity(0.98))
                    .offset(x: 439 * sx, y: 38 * sy)
            }
        }
    }

    private var insertCoinLabel: some View {
        Text("INSERT\nCOIN")
            .font(.system(size: 12 * sx))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(red: 0.74, green: 0.76, blue: 0.77))
            .frame(width: 64 * sx, height: 36 * sy)
            .opacity(insertCoinLit ? 1 : 0.38)
            .animation(.easeInOut(duration: 0.45), value: insertCoinLit)
            .offset(x: 326 * sx, y: 63 * sy)
            .allowsHitTesting(false)
    }

    private var abButtons: some View {
        ZStack(alignment: .topLeading) {
            idleCircleButton("A", x: 393, y: 144, wobble: phase * 1.3)
            idleCircleButton("B", x: 430, y: 144, wobble: phase * 1.5 + 0.6)
        }
    }

    private func idleCircleButton(_ label: String, x: CGFloat, y: CGFloat, wobble: Double) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.98))
                .frame(width: 32 * sx, height: 32 * sy)
            Text(label)
                .font(.system(size: 24 * sx, weight: .light))
                .foregroundStyle(Color(red: 0.74, green: 0.76, blue: 0.77))
        }
        .scaleEffect(0.97 + sin(wobble) * 0.025)
        .offset(x: x * sx, y: y * sy)
    }

    private var genreTapTargets: some View {
        ForEach(displayGenres) { channel in
            Button {
                onGenreTap?(channel)
            } label: {
                Color.clear
                    .frame(width: 80 * sx, height: 22 * sy)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: 12 * sx, y: (genreY(channel) - 2) * sy)
            .accessibilityLabel(channel.displayLabel)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func imageLayer(_ name: String, w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .antialiased(false)
            .frame(width: w * sx, height: h * sy)
            .offset(x: x * sx, y: y * sy)
    }

    private func genreY(_ channel: VisualizerChannel) -> CGFloat {
        Self.designH * channel.yFraction
    }

    private func digitImage(for character: Character) -> String {
        switch character {
        case "1": ArcadeImage.digit1
        case "2": ArcadeImage.digit2
        case "3": ArcadeImage.digit3
        default: ArcadeImage.digit4
        }
    }
}
