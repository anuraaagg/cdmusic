import SwiftUI

// MARK: - FigmaArcadeDisplayView
//
// Embedded arcade screen — Figma `465:10827` (362 × 163 pt).
// Idle: single bundled PNG (bezels baked in — no duplicate SwiftUI frames).
// Playing: one black bezel + gray LCD well + cosmic VHS television.

struct FigmaArcadeDisplayView: View {
    var scale: CGFloat = 1
    /// When set, the bezel fills this box (width = cream content width, height = remaining cream slot).
    var fitSize: CGSize? = nil
    var selectedChannel: VisualizerChannel = .cosmicVHS
    var isPlaying: Bool = false
    var visualizerSpeed: Double = 1
    var bass: Double = 0.08
    var mid: Double = 0.06
    var high: Double = 0.06
    var spinAngle: Double = 0
    var metalTime: Double = 0
    var videoController: VisualizerVideoController
    var onGenreTap: ((VisualizerChannel) -> Void)?

    @State private var screenMode: ScreenMode = .idle

    private enum ScreenMode {
        case idle
        case visualizer
    }

    /// Figma outer bezel (`465:10827`).
    private static let outerW: CGFloat = 362
    private static let outerH: CGFloat = 163
    /// Inner LCD inset — `465:10829` (visualizer only).
    private static let innerInset = CGSize(width: 6, height: 10)
    private static let innerW: CGFloat = 350
    private static let innerH: CGFloat = 143.5
    /// Source art coordinate space (`298:14287`).
    private static let refSize = CGSize(width: 479, height: 195)

    var body: some View {
        arcadeBezel
            .onChange(of: isPlaying) { _, playing in
                withAnimation(.easeInOut(duration: 0.55)) {
                    screenMode = playing ? .visualizer : .idle
                }
            }
            .onAppear {
                screenMode = isPlaying ? .visualizer : .idle
            }
            .accessibilityIdentifier("arcade.display")
    }

    private var bezelWidth: CGFloat { fitSize?.width ?? Self.outerW * scale }
    private var bezelHeight: CGFloat { fitSize?.height ?? Self.outerH * scale }
    private var scaleX: CGFloat { bezelWidth / Self.outerW }
    private var scaleY: CGFloat { bezelHeight / Self.outerH }
    /// Horizontal reference scale — tap zones, corner radius, PNG fit.
    private var contentScale: CGFloat { scaleX }

    private var arcadeBezel: some View {
        let w = bezelWidth
        let h = bezelHeight

        return Group {
            switch screenMode {
            case .idle:
                idleBezel(width: w, height: h)
            case .visualizer:
                visualizerBezel(width: w, height: h)
            }
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 2 * contentScale, style: .continuous))
        .animation(.easeInOut(duration: 0.55), value: screenMode)
    }

    /// Layered LCD with subtle attract-mode motion (replaces static PNG).
    private func idleBezel(width w: CGFloat, height h: CGFloat) -> some View {
        ArcadeDisplayIdleView(
            width: w,
            height: h,
            selectedChannel: selectedChannel,
            bass: bass,
            mid: mid,
            high: high,
            onGenreTap: onGenreTap
        )
    }

    /// Programmatic LCD — single outer shell + inner well (no PNG overlay).
    private func visualizerBezel(width w: CGFloat, height h: CGFloat) -> some View {
        let innerW = Self.innerW * scaleX
        let innerH = Self.innerH * scaleY
        let insetX = Self.innerInset.width * scaleX
        let insetY = Self.innerInset.height * scaleY

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2 * contentScale, style: .continuous)
                .fill(Color(red: 1 / 255, green: 1 / 255, blue: 1 / 255))

            RoundedRectangle(cornerRadius: 1.5 * contentScale, style: .continuous)
                .fill(Color(red: 191 / 255, green: 196 / 255, blue: 199 / 255))
                .frame(width: innerW, height: innerH)
                .offset(x: insetX, y: insetY)

            CosmicVHSTelevisionView(
                channel: selectedChannel,
                time: metalTime,
                bass: bass,
                mid: mid,
                high: high,
                spinAngle: spinAngle,
                speed: visualizerSpeed,
                videoController: videoController
            )
            .frame(width: innerW, height: innerH, alignment: .center)
            .offset(x: insetX, y: insetY)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 1 * contentScale, style: .continuous))
        }
        .frame(width: w, height: h)
    }
}

#Preview("Arcade display — idle") {
    FigmaArcadeDisplayView(scale: 1, selectedChannel: .cosmicVHS, isPlaying: false, videoController: VisualizerVideoController())
        .padding()
        .background(FigmaTheme.visualPanelCream)
}

#Preview("Arcade display — playing") {
    FigmaArcadeDisplayView(scale: 1, selectedChannel: .nebulaDream, isPlaying: true, videoController: VisualizerVideoController())
        .padding()
        .background(FigmaTheme.visualPanelCream)
}
