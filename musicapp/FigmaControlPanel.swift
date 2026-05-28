import SwiftUI

/// Figma control sheet — `332:4641` / `465:10794` inside `305:3451`.
///
/// Two full pages (groove + JAM + cream) slide horizontally. Vertical drag on
/// either page reveals CRATES underneath.
struct FigmaControlPanel: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @Binding var revealFraction: CGFloat
    @Binding var displayRevealFraction: CGFloat
    var expandedHeight: CGFloat? = nil
    var maxSlideDistance: CGFloat = 0
    var slideOffset: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    var spacing: FigmaResponsiveSpacing = .init(tightness: 1, scale: 1, tier: .large)

    @State private var innerPressed = false
    @State private var visualInnerPressed = false
    @State private var scrubLabel: String?
    @State private var seekAnchor = 0.0
    @State private var dragAnchor: CGFloat = 0
    @State private var isDragging = false
    @State private var drawerSettledOpen = false
    @State private var slideSoundPlayedThisGesture = false
    @State private var pageDragAnchor: CGFloat = 0
    @State private var isPageDragging = false
    @State private var pageDrawerSettledOpen = false
    @State private var pageSlideSoundPlayedThisGesture = false
    @State private var visualScrubAnchor = 0.0
    @State private var metalTime: Double = 0

    private let metalTick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var s: CGFloat { vm.figmaLayoutScale }

    private static let arcadeDisplayH: CGFloat = 163

    private var collapsedH: CGFloat { FigmaTheme.panelCollapsedH * s }

    private var expandedH: CGFloat {
        expandedHeight ?? FigmaTheme.panelExpandedH * s
    }

    private var maxSlide: CGFloat {
        maxSlideDistance > 0 ? maxSlideDistance : max(0, expandedH - collapsedH)
    }

    private var visualPageBlend: Double {
        max(0, min(1, 1 - Double(displayRevealFraction)))
    }

    var body: some View {
        horizontalPanelPager
            .frame(height: expandedH, alignment: .top)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    FigmaTheme.panelGrey
                    FigmaTheme.visualPanelCream
                        .opacity(visualPageBlend)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: FigmaTheme.panelCornerRadius * s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FigmaTheme.panelCornerRadius * s, style: .continuous)
                    .stroke(FigmaTheme.hairlineBorder.opacity(0.35), lineWidth: 0.65)
                    .allowsHitTesting(false)
            )
            .offset(y: slideOffset)
            .animation(isDragging ? nil : PanelDrawerPhysics.panelSlideAnimation(), value: slideOffset)
            .animation(isPageDragging ? nil : VisualizerDrawerPhysics.panelSlideAnimation(), value: displayRevealFraction)
            .animation(nil, value: vm.isPlaying)
            .onReceive(metalTick) { _ in
                if vm.isPlaying { metalTime += 1.0 / 60.0 }
            }
    }

    // MARK: - Full-panel horizontal pager (groove + JAM + cream move together)

    private var horizontalPanelPager: some View {
        GeometryReader { geo in
            let pageW = geo.size.width

            HStack(alignment: .top, spacing: 0) {
                fullPanelPage(
                    width: pageW,
                    height: geo.size.height,
                    isVisualPage: false
                )
                fullPanelPage(
                    width: pageW,
                    height: geo.size.height,
                    isVisualPage: true
                )
            }
            .offset(x: -pageSlideOffset(pageWidth: pageW))
            .gesture(pageDragGesture(pageWidth: pageW))
        }
        .padding(.bottom, safeAreaBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func fullPanelPage(width: CGFloat, height: CGFloat, isVisualPage: Bool) -> some View {
        let drawerReveal = isDragging ? dragAnchor : revealFraction
        let drawerJam = vm.jamToolbarForDrawer(
            revealFraction: drawerReveal,
            visualizerReveal: isPageDragging ? pageDragAnchor : displayRevealFraction
        )
        let status = isVisualPage && displayRevealFraction < 0.35
            ? drawerJam.status
            : (scrubLabel ?? drawerJam.status)

        return VStack(spacing: FigmaTheme.sheetBlockGap * s) {
            FigmaSheetTopGroove(scale: s)
                .contentShape(Rectangle())
                .gesture(panelDrag)

            FigmaJamToolbar(
                statusText: status,
                counterText: drawerJam.counter,
                scale: s,
                isPlaying: vm.isPlaying,
                showsBackArrow: isVisualPage,
                onDialTap: { vm.openLibrary() },
                onArrowTap: {
                    vm.impact(.light)
                    if isVisualPage {
                        vm.dismissDisplayScreen()
                    } else {
                        vm.showDisplayScreen()
                    }
                }
            )
            .padding(.top, spacing.sheetGrooveToJamPadding)
            .contentShape(Rectangle())
            .gesture(panelDrag)

            Group {
                if isVisualPage {
                    visualCreamContent
                } else {
                    controlCreamContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: width, height: height, alignment: .top)
        .opacity(pageOpacity(isVisualPage: isVisualPage))
        .accessibilityIdentifier(isVisualPage ? "arcade.visualPage" : "control.page")
        .allowsHitTesting(isVisualPage ? displayRevealFraction < 0.5 : displayRevealFraction > 0.5)
        .accessibilityHidden(isVisualPage ? displayRevealFraction > 0.5 : displayRevealFraction < 0.5)
    }

    // MARK: - Vertical drag — groove + JAM (crate reveal)

    private var panelDrag: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragAnchor = revealFraction
                    drawerSettledOpen = revealFraction < 0.08
                    slideSoundPlayedThisGesture = false
                    vm.impact(.soft)
                }
                guard maxSlide > 0 else { return }
                let delta = value.translation.height / maxSlide
                let next = PanelDrawerPhysics.resistedDragFraction(anchor: dragAnchor, delta: delta)
                if !slideSoundPlayedThisGesture, next < 0.72, dragAnchor >= 0.72 {
                    slideSoundPlayedThisGesture = true
                    vm.playDrawerSlideSound()
                }
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    revealFraction = next
                }
            }
            .onEnded { value in
                isDragging = false
                let flick = value.predictedEndTranslation.height - value.translation.height
                let settle = PanelDrawerPhysics.settleTarget(
                    revealFraction: revealFraction,
                    flickPixels: flick,
                    maxSlide: maxSlide
                )
                let target = settle.target
                if target == 0, !drawerSettledOpen, !slideSoundPlayedThisGesture {
                    vm.playDrawerSlideSound()
                } else if target == 1, revealFraction < 0.92 {
                    vm.playDrawerLatchSound()
                }
                drawerSettledOpen = target < 0.08
                vm.selectionChanged()
                withAnimation(PanelDrawerPhysics.settleAnimation(initialVelocity: settle.initialVelocity)) {
                    revealFraction = target
                }
            }
    }

    private func pageSlideOffset(pageWidth: CGFloat) -> CGFloat {
        (1 - displayRevealFraction) * pageWidth
    }

    /// Hide the settled off-screen page so its pixels never stack on the visible one.
    private func pageOpacity(isVisualPage: Bool) -> Double {
        if isPageDragging { return 1 }
        let onControlPage = displayRevealFraction > 0.01
        return isVisualPage ? (onControlPage ? 0 : 1) : (onControlPage ? 1 : 0)
    }

    private func pageDragGesture(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                let absH = abs(value.translation.height)
                let absW = abs(value.translation.width)
                guard absW > absH else { return }

                if !isPageDragging {
                    isPageDragging = true
                    pageDragAnchor = displayRevealFraction
                    pageDrawerSettledOpen = displayRevealFraction < 0.08
                    pageSlideSoundPlayedThisGesture = false
                    vm.impact(.soft)
                }
                guard pageWidth > 0 else { return }
                let delta = -value.translation.width / pageWidth
                let next = VisualizerDrawerPhysics.resistedDragFraction(anchor: pageDragAnchor, delta: delta)
                if !pageSlideSoundPlayedThisGesture, next < 0.72, pageDragAnchor >= 0.72 {
                    pageSlideSoundPlayedThisGesture = true
                    vm.playDrawerSlideSound()
                }
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    displayRevealFraction = next
                }
            }
            .onEnded { value in
                guard isPageDragging else { return }
                isPageDragging = false
                let flick = value.predictedEndTranslation.width - value.translation.width
                let settle = VisualizerDrawerPhysics.settleTarget(
                    revealFraction: displayRevealFraction,
                    flickPixels: flick,
                    maxSlide: pageWidth
                )
                let target = settle.target
                if target == 0, !pageDrawerSettledOpen, !pageSlideSoundPlayedThisGesture {
                    vm.playDrawerSlideSound()
                } else if target == 1, displayRevealFraction < 0.92 {
                    vm.playDrawerLatchSound()
                }
                pageDrawerSettledOpen = target < 0.08
                vm.selectionChanged()
                withAnimation(VisualizerDrawerPhysics.settleAnimation(initialVelocity: settle.initialVelocity)) {
                    displayRevealFraction = target
                }
            }
    }

    // MARK: - Cream interiors

    private var controlCreamContent: some View {
        VStack(spacing: FigmaTheme.creamPanelSectionGap * s) {
            controlTransportRow
            buttonGrid
        }
        .padding(.horizontal, FigmaTheme.creamPanelHPadding * s)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var visualCreamContent: some View {
        GeometryReader { geo in
            let hPad = FigmaTheme.creamPanelHPadding * s
            let creamW = geo.size.width
            let creamH = geo.size.height
            let layout = visualCreamLayout(creamWidth: creamW, creamHeight: creamH, hPad: hPad)

            VStack(spacing: 0) {
                FigmaArcadeDisplayView(
                    fitSize: CGSize(width: layout.displayWidth, height: layout.displayHeight),
                    selectedChannel: vm.visualizerChannel,
                    isPlaying: vm.isPlaying,
                    visualizerSpeed: vm.visualizerSpeed,
                    bass: vm.audioAnalyzer.bass,
                    mid: vm.audioAnalyzer.mid,
                    high: vm.audioAnalyzer.high,
                    spinAngle: vm.cdAngle,
                    metalTime: metalTime,
                    videoController: vm.visualizerVideoController,
                    onGenreTap: { vm.selectVisualizerChannel($0) }
                )
                .frame(width: layout.displayWidth, height: layout.displayHeight)

                Spacer(minLength: layout.gap)

                visualTransportRow(
                    podDiameter: layout.podDiameter,
                    podScale: s,
                    shadowBleed: layout.shadowBleed
                )
            }
            .padding(.horizontal, hPad)
            .padding(.top, layout.padTop)
            .padding(.bottom, layout.padBottom)
            .frame(width: creamW, height: creamH, alignment: .top)
        }
    }

    private struct VisualCreamLayout {
        let displayWidth: CGFloat
        let displayHeight: CGFloat
        let gap: CGFloat
        let padTop: CGFloat
        let padBottom: CGFloat
        let podDiameter: CGFloat
        let shadowBleed: CGFloat
    }

    /// Full-width display, transport pinned to bottom of cream slot.
    private func visualCreamLayout(creamWidth: CGFloat, creamHeight: CGFloat, hPad: CGFloat) -> VisualCreamLayout {
        let displayW = max(0, creamWidth - hPad * 2)
        let padTop = FigmaTheme.visualCreamTopPadding * s
        let padBottom = FigmaTheme.visualCreamBottomPadding * s
        let gap = FigmaTheme.visualDisplayTransportGapTight * s
        let overhead = padTop + padBottom + gap

        var pod = FigmaTheme.visualPodSize * s
        var shadow = jogShadowBleed(forPod: pod)
        let preferredDisplayH = Self.arcadeDisplayH * s

        if overhead + preferredDisplayH + pod + shadow > creamHeight {
            let podBudget = creamHeight - overhead - preferredDisplayH - jogShadowBleed(forPod: 92 * s)
            pod = max(92 * s, min(pod, podBudget))
            shadow = jogShadowBleed(forPod: pod)
        }

        let displayH = max(96 * s, creamHeight - overhead - pod - shadow)

        return VisualCreamLayout(
            displayWidth: displayW,
            displayHeight: displayH,
            gap: gap,
            padTop: padTop,
            padBottom: padBottom,
            podDiameter: pod,
            shadowBleed: shadow
        )
    }

    private func jogShadowBleed(forPod pod: CGFloat) -> CGFloat {
        FigmaTheme.jogShadowBleed * (pod / (FigmaTheme.visualPodSize * s))
    }

    // MARK: - Transport rows

    private var controlTransportRow: some View {
        HStack(alignment: .center, spacing: 0) {
            playPauseColumn

            Spacer(minLength: 0)

            controlJogWheel
                .frame(width: FigmaTheme.jogWheelDiameter * s, height: FigmaTheme.jogWheelDiameter * s)

            Spacer(minLength: 0)

            FigmaVolControl3375622(
                vm: vm,
                height: FigmaTheme.transportRowHeight * s,
                scale: s
            )
        }
        .frame(height: FigmaTheme.transportRowHeight * s)
    }

    private func visualTransportRow(podDiameter: CGFloat, podScale: CGFloat, shadowBleed: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            FigmaD7VentPod(scale: podScale)
                .frame(width: podDiameter, height: podDiameter)

            Spacer(minLength: 0)

            visualJogWheel(diameter: podDiameter)
                .frame(width: podDiameter, height: podDiameter)

            Spacer(minLength: 0)

            FigmaG4MeterPod(needleAngle: vm.g4MeterNeedleAngle, scale: podScale)
                .frame(width: podDiameter, height: podDiameter)
        }
        .frame(height: podDiameter + shadowBleed, alignment: .top)
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

    private var controlJogWheel: some View {
        jogWheel(
            diameter: FigmaTheme.jogWheelDiameter * s,
            innerPressed: $innerPressed,
            onCenterTap: {
                innerPressed = true
                vm.togglePlay()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { innerPressed = false }
            },
            onJiggleDrag: { offset, maxJ in
                vm.updateJogDragSpin(translation: offset, maxDeflection: maxJ)
            }
        )
    }

    private func visualJogWheel(diameter: CGFloat) -> some View {
        FigmaJogWheel(
            diameter: diameter,
            rotation: $vm.cdAngle,
            isPlaying: vm.isPlaying,
            isActive: vm.isPlaying,
            innerPressed: visualInnerPressed,
            enableHaptics: vm.isHapticEnabled,
            onCenterTap: {
                visualInnerPressed = true
                vm.cycleVisualizerChannel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { visualInnerPressed = false }
            },
            onSnapForward: {
                vm.visualizerVideoNextClip()
            },
            onSnapBack: {
                vm.visualizerVideoToggleReverse()
            },
            onJiggleSeekForward: {
                vm.visualizerVideoNextClip()
            },
            onJiggleSeekBack: {
                vm.visualizerVideoToggleReverse()
            },
            onJiggleDrag: { offset, maxJ in
                let mag = min(1, hypot(offset.width, offset.height) / max(maxJ, 1))
                vm.visualizerSpeed = 0.35 + mag * 2.15
                vm.syncVisualizerVideoPlayback()
                vm.updateJogDragSpin(translation: offset, maxDeflection: maxJ)
            },
            onJiggleDragEnd: {
                vm.endJogDragSpin()
            },
            onJogBegin: {
                visualScrubAnchor = vm.visualizerVideoController.scrubFraction
            },
            onScrub: { delta in
                vm.visualizerVideoScrub(degrees: delta, anchor: visualScrubAnchor)
            },
            onScrubEnd: { },
            onScratchDelta: { delta, velocity in
                vm.visualizerVideoScratch(delta: delta, velocity: velocity)
            },
            onScratchEnd: { }
        )
    }

    private func jogWheel(
        diameter: CGFloat,
        innerPressed: Binding<Bool>,
        onCenterTap: @escaping () -> Void,
        onJiggleDrag: @escaping (CGSize, CGFloat) -> Void
    ) -> some View {
        FigmaJogWheel(
            diameter: diameter,
            rotation: $vm.cdAngle,
            isPlaying: vm.isPlaying,
            isActive: vm.isPlaying || scrubLabel != nil,
            innerPressed: innerPressed.wrappedValue,
            enableHaptics: vm.isHapticEnabled,
            onCenterTap: onCenterTap,
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
            onJiggleDrag: onJiggleDrag,
            onJiggleDragEnd: { vm.endJogDragSpin() },
            onJogBegin: { seekAnchor = vm.progress },
            onScrub: { delta in
                vm.seek(to: min(1, max(0, seekAnchor + delta / 360.0)))
                scrubLabel = vm.currentTimeString
            },
            onScrubEnd: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { scrubLabel = nil }
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

    private var repeatCaption: String {
        switch vm.repeatMode {
        case .none: return "REPEAT"
        case .one: return "REPEAT ONE"
        case .all: return "REPEAT ALL"
        }
    }
}

#Preview("Control page") {
    FigmaControlPanel(
        vm: MusicPlayerViewModel(),
        revealFraction: .constant(1),
        displayRevealFraction: .constant(1),
        maxSlideDistance: 280,
        slideOffset: 0
    )
    .frame(width: 402, height: 380)
    .clipped()
}

#Preview("Visual page") {
    FigmaControlPanel(
        vm: MusicPlayerViewModel(),
        revealFraction: .constant(1),
        displayRevealFraction: .constant(0),
        maxSlideDistance: 280,
        slideOffset: 0
    )
    .frame(width: 402, height: 380)
    .clipped()
}
