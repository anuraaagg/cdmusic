import SwiftUI

/// Colorful retro TV / VHS screen — dedicated playing state for the arcade LCD.
struct CosmicVHSTelevisionView: View {
    var channel: VisualizerChannel
    var time: Double
    var bass: Double
    var mid: Double
    var high: Double
    var spinAngle: Double
    var speed: Double = 1
    @ObservedObject var videoController: VisualizerVideoController

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                VisualizerVideoPlayerView(
                    channel: channel,
                    time: time,
                    bass: bass,
                    mid: mid,
                    high: high,
                    speed: speed,
                    controller: videoController
                )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // Phosphor scanlines
                ScanlineOverlay(spacing: 3, opacity: 0.09)

                // Extra film grain on the glass
                FilmGrainOverlay(time: time, opacity: 0.05 + bass * 0.03)

                // CRT vignette + tube curvature feel
                RadialGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.08),
                        .black.opacity(0.42),
                    ],
                    center: .center,
                    startRadius: geo.size.width * 0.18,
                    endRadius: max(geo.size.width, geo.size.height) * 0.72
                )
                .allowsHitTesting(false)

                // RGB fringe on the glass edge
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0.2, blue: 0.35).opacity(0.35),
                                Color(red: 0.2, green: 0.85, blue: 1).opacity(0.28),
                                Color(red: 0.55, green: 1, blue: 0.35).opacity(0.22),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                    .padding(1)

                // Tracking bar drift
                VHSTrackingLine(time: time)
                    .allowsHitTesting(false)

                // Channel badge
                VStack {
                    HStack {
                        Text(channel.displayLabel)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.45))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                                    )
                            )
                        Spacer()
                        if videoController.isReversed {
                            Text("◀ REV")
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.cyan.opacity(0.85))
                        }
                        Text("● REC")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(red: 1, green: 0.25, blue: 0.3))
                            .opacity(0.55 + bass * 0.45)
                        Spacer().frame(width: 6)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    Spacer()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear { videoController.resumeIfNeeded() }
        .allowsHitTesting(false)
    }
}

private struct ScanlineOverlay: View {
    var spacing: CGFloat
    var opacity: Double

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                var line = Path()
                line.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                context.fill(line, with: .color(.black.opacity(opacity)))
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FilmGrainOverlay: View {
    var time: Double
    var opacity: Double

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 2
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let seed = sin(x * 12.9898 + y * 78.233 + time * 47.0) * 43758.5453
                    let n = seed - floor(seed)
                    let shade = n > 0.52 ? Color.white.opacity(opacity * 0.55) : Color.black.opacity(opacity * 0.45)
                    var dot = Path()
                    dot.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                    context.fill(dot, with: .color(shade))
                    x += step
                }
                y += step
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

private struct VHSTrackingLine: View {
    var time: Double

    var body: some View {
        GeometryReader { geo in
            let y = (sin(time * 0.7) * 0.5 + 0.5) * geo.size.height
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: y)
                .blur(radius: 0.6)
        }
    }
}

#Preview("VHS TV") {
    CosmicVHSTelevisionView(
        channel: .cosmicVHS,
        time: 12,
        bass: 0.6,
        mid: 0.4,
        high: 0.3,
        spinAngle: 40,
        videoController: VisualizerVideoController()
    )
    .frame(width: 350, height: 144)
    .clipShape(RoundedRectangle(cornerRadius: 2))
}
