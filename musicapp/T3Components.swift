import SwiftUI
import AVKit

// MARK: - Machine mark (dot grid)

struct T3MachineMark: View {
    var size: CGFloat = 40

    var body: some View {
        Canvas { ctx, canvasSize in
            let dot: CGFloat = max(2, size * 0.19)
            let gap: CGFloat = max(2.5, size * 0.20)
            let cols = 5
            let rows = 5
            let gridW = CGFloat(cols - 1) * (dot + gap) + dot
            let gridH = CGFloat(rows - 1) * (dot + gap) + dot
            let ox = (canvasSize.width - gridW) / 2
            let oy = (canvasSize.height - gridH) / 2

            for row in 0..<rows {
                for col in 0..<cols {
                    if row == 0 && (col == 0 || col == cols - 1) { continue }
                    if row == rows - 1 && (col == 0 || col == cols - 1) { continue }
                    let x = ox + CGFloat(col) * (dot + gap)
                    let y = oy + CGFloat(row) * (dot + gap)
                    let rect = CGRect(x: x, y: y, width: dot, height: dot)
                    ctx.fill(Path(ellipseIn: rect), with: .color(T3Color.textPrimary))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Indicator LED

struct T3Indicator: View {
    var isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? T3Color.ledOrange : T3Color.ledOff)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isOn ? 0.35 : 0.1), lineWidth: 0.5)
            )
            .shadow(color: isOn ? T3Color.ledOrange.opacity(0.55) : .clear, radius: 4)
    }
}

struct T3LedLabel: View {
    var text: String
    var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            T3Indicator(isOn: isOn)
            Text(text.uppercased())
                .font(T3Font.labelSmall(14))
                .foregroundColor(T3Color.bgDarkGrey)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

// MARK: - Power knob

struct T3PowerKnob: View {
    var size: CGFloat = 39
    var onVolumeChange: ((Double) -> Void)? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [T3Color.knobRing, T3Color.knobFace],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.20), radius: 2, y: 1)

            Circle()
                .fill(T3Color.knobFace)
                .frame(width: size * 0.56, height: size * 0.56)
                .shadow(color: .black.opacity(0.10), radius: 1, y: 0.5)
        }
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    let delta = -value.translation.height / 100
                    onVolumeChange?(delta)
                }
        )
    }
}

struct T3AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = UIColor(T3Color.labelDark)
        view.activeTintColor = UIColor(T3Color.bgOrange)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Mechanical block (606 shelf row)

enum T3BlockStyle {
    case white, grey, orange, black
}

struct T3MechanicalBlock: View {
    let label: String
    var detail: String? = nil
    var style: T3BlockStyle = .white
    var compact: Bool = false
    var action: (() -> Void)? = nil

    private var blockH: CGFloat { compact ? T3Layout.blockHeight : T3Layout.blockHeight }
    private var labelFont: Font {
        T3Font.labelMedium(compact ? 13 : 15)
    }
    private var blackLabelFont: Font {
        T3Font.labelMedium(compact ? 12 : 14)
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { blockContent }
                    .buttonStyle(T3PressStyle())
            } else {
                blockContent
            }
        }
        .frame(height: blockH)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var blockContent: some View {
        ZStack {
            switch style {
            case .white, .grey:
                RoundedRectangle(cornerRadius: 1)
                    .fill(style == .white ? T3Color.blockWhite : T3Color.blockGrey)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(Color(red: 0.34, green: 0.24, blue: 0.23), lineWidth: 0.4)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 16, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            case .orange:
                RoundedRectangle(cornerRadius: 1)
                    .fill(T3Color.bgOrange)
                    .shadow(color: T3Color.bgOrange.opacity(0.4), radius: 12, y: 4)
            case .black:
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [T3Color.blockBlackTop, T3Color.blockBlackBot],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(Color.black.opacity(0.7), lineWidth: 0.4)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 16, y: 0)
            }

            if style == .black, let detail {
                HStack {
                    Text(label.uppercased())
                        .font(blackLabelFont)
                        .foregroundColor(T3Color.labelBright)
                    Spacer()
                    Text(detail.uppercased())
                        .font(blackLabelFont)
                        .foregroundColor(T3Color.labelBright)
                }
                .padding(.horizontal, compact ? 14 : 18)
            } else {
                Text(label.uppercased())
                    .font(labelFont)
                    .foregroundColor(style == .white || style == .grey ? T3Color.labelDark : T3Color.labelBright)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .padding(.horizontal, compact ? 12 : 16)
            }
        }
    }
}

// MARK: - Buttons

struct T3ButtonHalf: View {
    let label: String
    var style: T3HalfStyle = .white
    var isActive: Bool = false
    var flex: Bool = false
    let action: () -> Void

    enum T3HalfStyle { case white, midGrey, orange }

    private var fill: Color {
        switch style {
        case .white: return .white
        case .midGrey: return Color(red: 0.55, green: 0.54, blue: 0.53)
        case .orange: return T3Color.bgOrange
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(T3Font.labelMedium(11))
                .foregroundColor(style == .white && !isActive ? T3Color.labelDark : T3Color.labelBright)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: flex ? .infinity : nil)
                .frame(width: flex ? nil : 115, height: T3Layout.buttonHalfH)
                .t3KeyCap(fill: isActive ? T3Color.bgOrange : fill)
        }
        .buttonStyle(T3PressStyle())
    }
}

struct T3Button: View {
    let label: String
    var style: T3ButtonStyle = .orange
    let action: () -> Void

    enum T3ButtonStyle { case orange, blackNum }

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(T3Font.labelMedium(12))
                .foregroundColor(T3Color.labelBright)
                .multilineTextAlignment(.center)
                .frame(width: T3Layout.buttonSize, height: T3Layout.buttonSize)
                .t3KeyCap(
                    fill: style == .orange ? T3Color.bgOrange : Color(red: 0.12, green: 0.12, blue: 0.12),
                    cornerRadius: T3Layout.keyCapRadius
                )
        }
        .buttonStyle(T3PressStyle())
    }
}

struct T3ButtonHybrid: View {
    let label: String
    var isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(T3Font.labelMedium(24))
                .foregroundColor(isOn ? T3Color.labelBright : T3Color.labelDark)
                .frame(maxWidth: .infinity)
                .frame(height: T3Layout.buttonSize * 0.55)
                .t3KeyCap(
                    fill: isOn ? Color(red: 0.18, green: 0.18, blue: 0.18) : T3Color.blockWhite,
                    cornerRadius: 16
                )
        }
        .buttonStyle(T3PressStyle())
    }
}

enum T3SymbolKind {
    case asterisk, `return`, lift, drop

    var glyph: String {
        switch self {
        case .asterisk: return "✱"
        case .return: return "↩"
        case .lift: return "↑"
        case .drop: return "↓"
        }
    }
}

struct T3ButtonSymbol: View {
    let kind: T3SymbolKind
    var size: CGFloat = 34
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(kind.glyph)
                .font(T3Font.labelSmall(14))
                .foregroundColor(T3Color.labelDark)
                .frame(width: size, height: size)
                .background(T3Color.blockWhite)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(T3PressStyle())
    }
}

// MARK: - Library header

struct T3LibraryHeader: View {
    let title: String
    let rangeLabel: String
    var onMarkTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Button {
                onMarkTap?()
            } label: {
                ZStack {
                    Circle()
                        .fill(T3Color.surfacePrimary)
                        .frame(width: T3Layout.headerHeight, height: T3Layout.headerHeight)
                    T3MachineMark(size: 24)
                }
            }
            .buttonStyle(.plain)

            T3CreamPill(text: title)
                .frame(maxWidth: .infinity)

            T3CreamPill(text: rangeLabel, fixed: true)
        }
        .frame(height: T3Layout.headerHeight)
    }
}

struct T3CreamPill: View {
    let text: String
    var fixed: Bool = false

    var body: some View {
        Text(text.uppercased())
            .font(T3Font.header(10))
            .foregroundColor(T3Color.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: fixed ? nil : .infinity)
            .background(
                Capsule().fill(T3Color.surfacePrimary)
            )
    }
}

// MARK: - Jog dial

struct T3JogDial: View {
    /// When false, ring/inner are clear so raster artwork can sit underneath.
    var useProceduralAppearance: Bool = true
    var diameter: CGFloat = T3Layout.knobSize
    @Binding var rotation: Double
    var isActive: Bool
    var isPlaying: Bool
    var innerPressed: Bool
    var onCenterTap: () -> Void
    var onSnapForward: () -> Void
    var onSnapBack: () -> Void
    var onScrub: (Double) -> Void
    var onScrubEnd: () -> Void
    var onScratchDelta: ((Double, Double) -> Void)? = nil
    var onScratchEnd: (() -> Void)? = nil

    @State private var dragStartAngle: Double?
    @State private var dragStartRotation: Double = 0
    @State private var accumulatedDelta: Double = 0
    @State private var isDragging = false
    @State private var lastScratchAngle: Double?
    @State private var lastScratchTime: Date?

    private var size: CGFloat { diameter }
    private let snapThreshold: Double = 12

    var body: some View {
        ZStack {
            ZStack {
                outerRingFace
                innerDisc
            }
            .rotationEffect(.degrees(rotation))
            .animation(isDragging ? nil : .spring(response: 0.35, dampingFraction: 0.72), value: rotation)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(outerDrag)
    }

    private var outerRingFace: some View {
        Group {
            if useProceduralAppearance {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [T3Color.knobFace, T3Color.knobRing],
                            center: .init(x: 0.35, y: 0.3),
                            startRadius: 0,
                            endRadius: size * 0.55
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
            } else {
                Circle().fill(Color.clear)
            }
        }
    }

    private var outerDrag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isDragging = true
                let center = CGPoint(x: size / 2, y: size / 2)
                let angle = atan2(value.location.y - center.y, value.location.x - center.x) * 180 / .pi
                let now = Date()

                if let last = lastScratchAngle, let lastTime = lastScratchTime {
                    var scratchDelta = angle - last
                    if scratchDelta > 180 { scratchDelta -= 360 }
                    if scratchDelta < -180 { scratchDelta += 360 }
                    let dt = max(0.001, now.timeIntervalSince(lastTime))
                    let velocity = scratchDelta / dt / 60
                    onScratchDelta?(scratchDelta, velocity)
                }
                lastScratchAngle = angle
                lastScratchTime = now

                if dragStartAngle == nil {
                    dragStartAngle = angle
                    dragStartRotation = rotation
                    accumulatedDelta = 0
                } else if let start = dragStartAngle {
                    var delta = angle - start
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    accumulatedDelta = delta
                    rotation = dragStartRotation + delta
                    let frac = min(1, max(0, 0.5 + delta / 180))
                    onScrub(frac)
                }
            }
            .onEnded { _ in
                isDragging = false
                lastScratchAngle = nil
                lastScratchTime = nil
                onScratchEnd?()

                if accumulatedDelta >= snapThreshold {
                    onSnapForward()
                    rotation = 15
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { rotation = 0 }
                } else if accumulatedDelta <= -snapThreshold {
                    onSnapBack()
                    rotation = -15
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { rotation = 0 }
                } else {
                    rotation = 0
                }
                dragStartAngle = nil
                accumulatedDelta = 0
                onScrubEnd()
            }
    }

    private var innerDisc: some View {
        Group {
            if useProceduralAppearance {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), T3Color.knobFace],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.48, height: size * 0.48)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                    .shadow(
                        color: innerPressed ? .clear : .black.opacity(0.15),
                        radius: innerPressed ? 2 : 6,
                        y: innerPressed ? 1 : 4
                    )
                    .scaleEffect(innerPressed ? 0.96 : 1)
                    .animation(.easeOut(duration: 0.12), value: innerPressed)
                    .onTapGesture { onCenterTap() }
                    .overlay(
                        Circle()
                            .fill(isActive ? T3Color.bgOrange.opacity(0.12) : Color.clear)
                    )
            } else {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .frame(width: size * 0.48, height: size * 0.48)
                    .onTapGesture { onCenterTap() }
            }
        }
    }
}

struct T3PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.14, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
