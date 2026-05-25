import SwiftUI

/// Figma control sheet — `332:4641` inside `305:3451`.
///
/// Always renders at full expanded height and **translates** down (`slideOffset`)
/// to reveal `FigmaCrateView` underneath — never shrinks (drawer physics).
struct FigmaControlPanel: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @Binding var revealFraction: CGFloat
    var expandedHeight: CGFloat? = nil
    var maxSlideDistance: CGFloat = 0
    var slideOffset: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    var spacing: FigmaResponsiveSpacing = .init(tightness: 1, scale: 1, tier: .large)

    @State private var innerPressed = false
    @State private var scrubLabel: String?
    @State private var seekAnchor = 0.0
    @State private var dragAnchor: CGFloat = 0
    @State private var isDragging = false

    private var s: CGFloat { vm.figmaLayoutScale }

    private var collapsedH: CGFloat { FigmaTheme.panelCollapsedH * s }

    private var expandedH: CGFloat {
        expandedHeight ?? FigmaTheme.panelExpandedH * s
    }

    private var maxSlide: CGFloat {
        maxSlideDistance > 0 ? maxSlideDistance : max(0, expandedH - collapsedH)
    }

    var body: some View {
        VStack(spacing: FigmaTheme.sheetBlockGap * s) {
            sheetTopGroove
            jamRowBlock
            creamPanel
        }
        .frame(height: expandedH, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(FigmaTheme.panelGrey)
        .clipShape(RoundedRectangle(cornerRadius: FigmaTheme.panelCornerRadius * s, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FigmaTheme.panelCornerRadius * s, style: .continuous)
                .stroke(FigmaTheme.hairlineBorder.opacity(0.35), lineWidth: 0.65)
                .allowsHitTesting(false)
        )
        .offset(y: slideOffset)
        .animation(isDragging ? nil : .spring(response: 0.38, dampingFraction: 0.88), value: slideOffset)
        .animation(nil, value: vm.isPlaying)
    }

    // MARK: - Drag target — groove + JAM row

    private var sheetTopGroove: some View {
        FigmaSheetTopGroove(scale: s)
            .contentShape(Rectangle())
            .gesture(panelDrag)
    }

    private var jamRowBlock: some View {
        jamToolbar
            .padding(.top, spacing.sheetGrooveToJamPadding)
            .contentShape(Rectangle())
            .gesture(panelDrag)
    }

    private var panelDrag: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragAnchor = revealFraction
                    vm.impact(.rigid)
                }
                guard maxSlide > 0 else { return }
                let delta = value.translation.height / maxSlide
                let next = max(0, min(1, dragAnchor - delta))
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    revealFraction = next
                }
            }
            .onEnded { value in
                isDragging = false
                let flick = value.predictedEndTranslation.height - value.translation.height
                var target: CGFloat = revealFraction >= 0.45 ? 1 : 0
                if flick > 80 { target = 0 }
                if flick < -80 { target = 1 }
                vm.selectionChanged()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    revealFraction = target
                }
            }
    }

    private var repeatCaption: String {
        switch vm.repeatMode {
        case .none: return "REPEAT"
        case .one: return "REPEAT ONE"
        case .all: return "REPEAT ALL"
        }
    }

    private var jamToolbar: some View {
        FigmaJamToolbar(
            statusText: scrubLabel ?? vm.jamStatusLine,
            counterText: vm.jamRangeCaption,
            scale: s,
            isPlaying: vm.isPlaying,
            onDialTap: { vm.openLibrary() }
        )
    }

    // MARK: - Cream panel (`305:3398`)

    private var creamPanel: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: spacing.creamSectionGap) {
                transportRow
                buttonGrid
            }
            .padding(.horizontal, FigmaTheme.creamPanelHPadding * s)

            Spacer(minLength: 0)
        }
        .padding(.bottom, spacing.creamBottomPadding + safeAreaBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var transportRow: some View {
        HStack(alignment: .center, spacing: 0) {
            playPauseColumn

            Spacer(minLength: 0)

            knobStack
                .frame(width: FigmaTheme.transportRowHeight * s, height: FigmaTheme.transportRowHeight * s)

            Spacer(minLength: 0)

            FigmaVolControl3375622(
                vm: vm,
                height: FigmaTheme.transportRowHeight * s,
                scale: s
            )
        }
        .frame(height: FigmaTheme.transportRowHeight * s)
    }

    private var playPauseColumn: some View {
        VStack(spacing: FigmaTheme.playPauseGap * s) {
            FigmaSquareButton.play(scale: s) {
                vm.impact(.light)
                if !vm.isPlaying { vm.togglePlay() }
            }
            FigmaSquareButton.pause(scale: s) {
                vm.impact(.light)
                if vm.isPlaying { vm.togglePlay() }
            }
        }
        .frame(
            width: FigmaTheme.playPauseColumnWidth * s,
            height: FigmaTheme.playPauseColumnHeight * s,
            alignment: .leading
        )
    }

    private var knobStack: some View {
        let knobD = FigmaTheme.jogWheelDiameter * s

        return FigmaJogWheel(
            diameter: knobD,
            rotation: $vm.cdAngle,
            isPlaying: vm.isPlaying,
            isActive: vm.isPlaying || scrubLabel != nil,
            innerPressed: innerPressed,
            enableHaptics: vm.isHapticEnabled,
            onCenterTap: {
                innerPressed = true
                vm.togglePlay()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { innerPressed = false }
            },
            onSnapForward: { vm.skipNext() },
            onSnapBack: { vm.skipPrevious() },
            onJiggleSeekForward: {
                vm.seek(bySeconds: 10)
                scrubLabel = vm.currentTimeString
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { scrubLabel = nil }
            },
            onJiggleSeekBack: {
                vm.seek(bySeconds: -10)
                scrubLabel = vm.currentTimeString
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { scrubLabel = nil }
            },
            onJogBegin: { seekAnchor = vm.progress },
            onScrub: { delta in
                vm.seek(to: min(1, max(0, seekAnchor + delta / 360.0)))
                scrubLabel = vm.currentTimeString
            },
            onScrubEnd: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    scrubLabel = nil
                }
            },
            onScratchDelta: { d, v in vm.scratch(delta: d, velocity: v) },
            onScratchEnd: vm.endScratch
        )
    }

    private var buttonGrid: some View {
        VStack(spacing: FigmaTheme.buttonGridRowGap * s) {
            HStack(spacing: FigmaTheme.buttonGridRowGap * s) {
                FigmaButtonHalf.orange(flex: true, scale: s) {
                    vm.impact(.light)
                    vm.skipPrevious()
                }
                FigmaButtonHalf.cream(flex: true, scale: s) {
                    vm.impact(.light)
                    vm.skipNext()
                }
            }
            .frame(height: FigmaButtonHalf.nativeHeight * s)

            HStack(spacing: FigmaTheme.buttonGridRowGap * s) {
                FigmaButtonHalf.midGrey(isActive: vm.isShuffle, flex: true, scale: s) {
                    vm.impact(.light)
                    vm.toggleShuffle()
                }
                FigmaButtonHalf.dark(
                    label: repeatCaption,
                    isActive: vm.repeatMode != .none,
                    flex: true,
                    scale: s
                ) {
                    vm.impact(.light)
                    vm.toggleRepeat()
                }
            }
            .frame(height: FigmaButtonHalf.nativeHeight * s)
        }
        .frame(height: FigmaTheme.buttonGridHeight * s, alignment: .top)
    }
}

#Preview("Control card — Figma 305:3451") {
    FigmaControlPanel(
        vm: MusicPlayerViewModel(),
        revealFraction: .constant(1),
        maxSlideDistance: 280,
        slideOffset: 0
    )
    .frame(width: 402, height: 380)
    .clipped()
}
