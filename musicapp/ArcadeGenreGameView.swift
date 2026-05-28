import SwiftUI

// MARK: - Game model

private enum ArcadeGenre: CaseIterable, Identifiable {
    case hipHop, disco, techno

    var id: String { label }

    var label: String {
        switch self {
        case .hipHop: "HIP-HOP"
        case .disco: "DISCO"
        case .techno: "TECHNO"
        }
    }

    var yFraction: CGFloat {
        switch self {
        case .hipHop: 0.108
        case .disco: 0.200
        case .techno: 0.292
        }
    }
}

private enum ArcadePhase {
    case attract
    case playing
    case gameOver
}

// MARK: - View

struct ArcadeGenreGameView: View {
    var onClose: () -> Void = {}

    @State private var phase: ArcadePhase = .attract
    @State private var score = 0
    @State private var lives = 3
    @State private var coins = 3
    @State private var target: ArcadeGenre = .disco
    @State private var spinAngle: Double = 0
    @State private var eqPhase: Double = 0
    @State private var timeLeft: Double = 3
    @State private var flashInsertCoin = true
    @State private var combo = 0
    @State private var isAM = true

    private let designSize = CGSize(width: 479, height: 195)
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let flashTimer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: 0.83, green: 0.82, blue: 0.80).ignoresSafeArea()

            VStack(spacing: 24) {
                header
                cabinet
                hintText
            }
            .padding(.horizontal, 20)
        }
        .onReceive(timer) { _ in tick() }
        .onReceive(flashTimer) { _ in
            if phase == .attract { flashInsertCoin.toggle() }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.35))
            }
            Spacer()
            Text("GENRE DROP ARCADE")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.55))
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
    }

    private var hintText: some View {
        Text(phaseHint)
            .font(.system(size: 14, weight: .regular, design: .monospaced))
            .foregroundStyle(.black.opacity(0.5))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 520)
    }

    private var phaseHint: String {
        switch phase {
        case .attract:
            "Tap INSERT COIN to play. Match the lit genre before the needle drops."
        case .playing:
            "Tap \(target.label) on the left panel. A = hint · B = skip · ★ = +1 coin"
        case .gameOver:
            "Game over — tap INSERT COIN to try again."
        }
    }

    private var cabinet: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / designSize.width, 1.4)
            let w = designSize.width * scale
            let h = designSize.height * scale

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6 * scale)
                    .fill(Color.black)
                    .frame(width: w, height: h)

                RoundedRectangle(cornerRadius: 4 * scale)
                    .fill(Color(red: 0.75, green: 0.77, blue: 0.78))
                    .frame(width: w - 16 * scale, height: h - 24 * scale)
                    .offset(x: 8 * scale, y: 15 * scale)

                displayContent(scale: scale, cabinetWidth: w)
            }
            .frame(width: w, height: h)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 280)
    }

    @ViewBuilder
    private func displayContent(scale: CGFloat, cabinetWidth: CGFloat) -> some View {
        let s = scale

        // Frame rails
        Image(ArcadeImage.frameLeft)
            .resizable()
            .frame(width: 159 * s, height: 129 * s)
            .offset(x: 156 * s, y: 18 * s)

        Image(ArcadeImage.frameLeftTrim)
            .resizable()
            .frame(width: 22 * s, height: 129 * s)
            .offset(x: 156 * s, y: 18 * s)

        Image(ArcadeImage.frameRightTrim)
            .resizable()
            .frame(width: 22 * s, height: 129 * s)
            .offset(x: 300 * s, y: 18 * s)

        Image(ArcadeImage.screenBezel)
            .resizable()
            .frame(width: 152 * s, height: 21 * s)
            .offset(x: 163 * s, y: 65 * s)

        // Genre labels
        ForEach(ArcadeGenre.allCases) { genre in
            genreLabel(genre, scale: s, highlighted: phase == .playing && genre == target)
        }

        // ARCADE title / target prompt
        Text(phase == .playing ? "MATCH!" : "ARCADE")
            .font(.system(size: 22 * s, weight: .regular))
            .foregroundStyle(Color(red: 0.74, green: 0.76, blue: 0.77))
            .frame(width: 140 * s)
            .offset(x: 169 * s, y: 32 * s)

        // Icon + equalizer
        Image(ArcadeImage.iconFrame)
            .resizable()
            .frame(width: 26 * s, height: 25 * s)
            .offset(x: 96 * s, y: 25 * s)

        Image(ArcadeImage.equalizer)
            .resizable()
            .frame(width: 30 * s, height: 78 * s)
            .offset(x: 94 * s, y: 89 * s)
            .scaleEffect(y: 0.85 + sin(eqPhase) * 0.15, anchor: .bottom)

        // Knobs + speakers
        Image(ArcadeImage.knobLeft)
            .resizable()
            .frame(width: 34 * s, height: 34 * s)
            .offset(x: 135 * s, y: 23 * s)
            .rotationEffect(.degrees(spinAngle * 0.4))

        Image(ArcadeImage.knobRight)
            .resizable()
            .frame(width: 34 * s, height: 34 * s)
            .offset(x: 309 * s, y: 23 * s)
            .rotationEffect(.degrees(-spinAngle * 0.35))

        Image(ArcadeImage.speakerLeft)
            .resizable()
            .frame(width: 18 * s, height: 13 * s)
            .offset(x: 186 * s, y: 69 * s)
            .opacity(phase == .playing ? 0.55 + sin(eqPhase * 2) * 0.45 : 0.7)

        Image(ArcadeImage.speakerRight)
            .resizable()
            .frame(width: 18 * s, height: 13 * s)
            .offset(x: 274 * s, y: 69 * s)
            .opacity(phase == .playing ? 0.55 + cos(eqPhase * 2) * 0.45 : 0.7)

        // Spinning vinyl grid
        Image(ArcadeImage.vinylGrid)
            .resizable()
            .frame(width: 44 * s, height: 44 * s)
            .offset(x: 217 * s, y: 94 * s)
            .rotationEffect(.degrees(spinAngle))

        // Score digits
        HStack(spacing: 2 * s) {
            ForEach(digitImages(for: score), id: \.self) { name in
                Image(name)
                    .resizable()
                    .frame(width: 15.4 * s, height: 29 * s)
            }
        }
        .offset(x: 358 * s, y: 23 * s)

        // AM/PM toggle
        amPmToggle(scale: s)

        // Insert coin
        Button(action: insertCoin) {
            Text("INSERT\nCOIN")
                .font(.system(size: 12 * s))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.74, green: 0.76, blue: 0.77))
                .frame(width: 64 * s, height: 36 * s)
                .opacity(phase == .attract && flashInsertCoin ? 1 : (phase == .gameOver ? 0.85 : 0.35))
        }
        .buttonStyle(.plain)
        .offset(x: 326 * s, y: 63 * s)

        // A / B
        arcadeButton(label: "A", scale: s, x: 393, y: 144, action: useHint)
        arcadeButton(label: "B", scale: s, x: 430, y: 144, action: skipRound)

        // Star / heart
        Button(action: bonusCoin) {
            Image(ArcadeImage.btnStar)
                .resizable()
                .frame(width: 22 * s, height: 22 * s)
        }
        .buttonStyle(.plain)
        .offset(x: 16 * s, y: 151 * s)

        HStack(spacing: 4 * s) {
            ForEach(0..<3, id: \.self) { i in
                Image(ArcadeImage.btnHeart)
                    .resizable()
                    .frame(width: 19 * s, height: 22 * s)
                    .opacity(i < lives ? 1 : 0.15)
            }
        }
        .offset(x: 41 * s, y: 151 * s)

        Image(ArcadeImage.controlsLeft)
            .resizable()
            .frame(width: 46 * s, height: 28 * s)
            .offset(x: 21 * s, y: 86 * s)

        Image(ArcadeImage.handle)
            .resizable()
            .frame(width: 166 * s, height: 26 * s)
            .offset(x: 156 * s, y: 151 * s)

        // Timer bar
        if phase == .playing {
            Capsule()
                .fill(Color.black.opacity(0.85))
                .frame(width: max(8, 140 * s * CGFloat(timeLeft / maxTime)), height: 5 * s)
                .offset(x: 169 * s, y: 150 * s)
        }

        // Genre tap targets
        ForEach(ArcadeGenre.allCases) { genre in
            Button(action: { pick(genre) }) {
                Color.clear
                    .frame(width: 80 * s, height: 22 * s)
            }
            .buttonStyle(.plain)
            .offset(x: 12 * s, y: (designSize.height * genre.yFraction - 2) * s)
            .disabled(phase != .playing)
        }
    }

    @ViewBuilder
    private func genreLabel(_ genre: ArcadeGenre, scale: CGFloat, highlighted: Bool) -> some View {
        let color: Color = {
            if highlighted { return .black }
            switch genre {
            case .hipHop: return .black
            case .disco: return Color(red: 0.69, green: 0.71, blue: 0.72)
            case .techno: return Color(red: 0.69, green: 0.71, blue: 0.72)
            }
        }()

        Text(genre.label)
            .font(.system(size: 16 * scale, weight: highlighted ? .bold : .regular))
            .foregroundStyle(color)
            .scaleEffect(highlighted ? 1.08 : 1, anchor: .leading)
            .animation(.spring(response: 0.25), value: highlighted)
            .offset(x: 16 * scale, y: designSize.height * genre.yFraction * scale)
    }

    @ViewBuilder
    private func amPmToggle(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Text("AM")
                .font(.system(size: 10 * scale))
                .foregroundStyle(isAM ? Color.black.opacity(0.98) : Color(red: 0.75, green: 0.77, blue: 0.78))
                .offset(x: 439 * scale, y: 25 * scale)
            RoundedRectangle(cornerRadius: 2)
                .fill(isAM ? Color(red: 0.69, green: 0.71, blue: 0.72) : Color.black.opacity(0.98))
                .frame(width: 20 * scale, height: 11 * scale)
                .offset(x: 437 * scale, y: 38 * scale)
            Text("PM")
                .font(.system(size: 10 * scale))
                .foregroundStyle(isAM ? Color(red: 0.75, green: 0.77, blue: 0.78) : Color.black.opacity(0.98))
                .offset(x: 439 * scale, y: 38 * scale)
        }
        .onTapGesture { isAM.toggle() }
    }

    @ViewBuilder
    private func arcadeButton(label: String, scale: CGFloat, x: CGFloat, y: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.98))
                    .frame(width: 32 * scale, height: 32 * scale)
                Text(label)
                    .font(.system(size: 24 * scale, weight: .light))
                    .foregroundStyle(Color(red: 0.74, green: 0.76, blue: 0.77))
            }
        }
        .buttonStyle(.plain)
        .offset(x: x * scale, y: y * scale)
        .disabled(phase != .playing)
    }

    // MARK: - Logic

    private var maxTime: Double {
        max(1.1, 3.0 - Double(score) * 0.08)
    }

    private func tick() {
        spinAngle = (spinAngle + 0.6 + Double(score) * 0.04).truncatingRemainder(dividingBy: 360)
        eqPhase += 0.12

        guard phase == .playing else { return }
        timeLeft -= 1.0 / 60.0
        if timeLeft <= 0 { wrongAnswer() }
    }

    private func insertCoin() {
        guard phase != .playing else { return }
        if phase == .gameOver || coins > 0 {
            if phase != .gameOver { coins -= 1 }
            score = phase == .gameOver ? 0 : score
            lives = 3
            combo = 0
            phase = .playing
            nextRound()
        }
    }

    private func nextRound() {
        target = ArcadeGenre.allCases.randomElement() ?? .disco
        timeLeft = maxTime
    }

    private func pick(_ genre: ArcadeGenre) {
        guard phase == .playing else { return }
        if genre == target {
            combo += 1
            score += 10 + combo * 2
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            nextRound()
        } else {
            wrongAnswer()
        }
    }

    private func wrongAnswer() {
        lives -= 1
        combo = 0
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        if lives <= 0 {
            phase = .gameOver
        } else {
            nextRound()
        }
    }

    private func useHint() {
        guard phase == .playing, score >= 5 else { return }
        score -= 5
        timeLeft = min(timeLeft + 0.8, maxTime)
    }

    private func skipRound() {
        guard phase == .playing else { return }
        score = max(0, score - 3)
        nextRound()
    }

    private func bonusCoin() {
        guard coins < 9 else { return }
        coins += 1
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func digitImages(for value: Int) -> [String] {
        let clamped = max(0, min(9999, value))
        let s = String(format: "%04d", clamped)
        return s.map { ch in
            switch ch {
            case "1": ArcadeImage.digit1
            case "2": ArcadeImage.digit2
            case "3": ArcadeImage.digit3
            default: ArcadeImage.digit4
            }
        }
    }
}

#Preview {
    ArcadeGenreGameView()
}
