import SwiftUI

// MARK: - FigmaCrateDropSheet
//
// Figma `397:3639` — hold vinyl / hero CD → peek sheet → auto-expand → drag or flick into 3D milk crate.

private enum CrateDropSheetDetent: Equatable {
    case peek
    case drop

    func height(screenHeight: CGFloat, bottomSafe: CGFloat, scale: CGFloat) -> CGFloat {
        switch self {
        case .peek:
            return min(screenHeight * 0.345, (256 + bottomSafe) * scale)
        case .drop:
            return screenHeight * 0.755
        }
    }
}

/// Geometry cached at drop commit so settling animation stays in sync with the layout pass.
private struct CrateSettleLayout: Equatable {
    let crateWidth: CGFloat
    let discDiameter: CGFloat
}

struct FigmaCrateDropSheet: View {
    @ObservedObject var vm: MusicPlayerViewModel

    @State private var sheetDetent: CrateDropSheetDetent = .peek
    @State private var vinylDragOffset: CGSize = .zero
    @State private var lastDragSample: (Date, CGSize)?
    @State private var dragVelocityY: CGFloat = 0
    @State private var hoveringOpening = false
    @State private var expandTask: Task<Void, Never>?
    @State private var discDragActive = false
    /// Target layout when `commitCrateDrop` runs — feeds the settle spring.
    @State private var pendingSettleLayout: CrateSettleLayout?

    /// Disc scales down as it flips into the crate slot.
    @State private var settlingScale: CGFloat = 1
    /// Card-flip pitch (INDmoney-style tilt back into depth).
    @State private var settlingTiltX: Double = 0
    @State private var settlingTiltY: Double = 0

    private var c: FigmaTheme.Crate.Type { FigmaTheme.Crate.self }

    private var active: Bool { vm.crateSavePhase != .idle }

    private var dropIndex: Int { vm.crateSaveDragIndex ?? vm.crateActiveIndex }

    var body: some View {
        if active {
            GeometryReader { geo in
                let screenH = geo.size.height
                let bottomInset = geo.safeAreaInsets.bottom
                let s = vm.figmaLayoutScale
                let sheetH = sheetDetent.height(screenHeight: screenH, bottomSafe: bottomInset, scale: s)
                let headerH = headerTotalHeight(scale: s)

                ZStack(alignment: .bottom) {
                    Color.black
                        .opacity(scrimOpacity(sheetHeight: sheetH, screenHeight: screenH))
                        .ignoresSafeArea()
                        .onTapGesture { vm.closeCrateDropSheetChrome() }

                    VStack(spacing: 0) {
                        dropHereHeader(scale: s)
                            .background(FigmaTheme.crateInner)

                        sheetBody(
                            contentHeight: max(120, sheetH - headerH - bottomInset),
                            scale: s,
                            fullWidth: geo.size.width
                        )
                        .background(FigmaTheme.crateInner)

                        if vm.crateSavePhase == .success {
                            Text("In your crate. Tap ✕ when you're ready.")
                                .font(.custom("Helvetica", size: 12 * s))
                                .tracking(-0.5 * s)
                                .foregroundStyle(FigmaTheme.textDark.opacity(0.44))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28 * s)
                                .padding(.top, 6 * s)
                                .padding(.bottom, max(14 * s, bottomInset * 0.35))
                                .accessibilityHint("Dismisses the crate sheet.")
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(height: sheetH, alignment: .top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .background(FigmaTheme.crateInner)
                    .clipShape(sheetShape(scale: s))
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("crate.dropSheet")
                    .onChange(of: vm.crateSavePhase) { _, phase in
                        if phase == .settling {
                            runSettleIntoCrate(scale: s)
                        } else if phase == .success {
                            // Keep landed flip pose visible until dismiss — do not reset transforms.
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                sheetDetent = .peek
                vinylDragOffset = .zero
                settlingScale = 1
                settlingTiltX = 0
                settlingTiltY = 0
                hoveringOpening = false
                pendingSettleLayout = nil
                lastDragSample = nil
                scheduleExpandIfPresenting()
            }
            .onDisappear {
                expandTask?.cancel()
                expandTask = nil
            }
            .onChange(of: vm.crateSavePhase) { _, phase in
                if phase == .idle {
                    expandTask?.cancel()
                    expandTask = nil
                    sheetDetent = .peek
                    vinylDragOffset = .zero
                    settlingScale = 1
                    settlingTiltX = 0
                    settlingTiltY = 0
                    hoveringOpening = false
                    pendingSettleLayout = nil
                }
            }
        }
    }

    // MARK: - Settle pipeline

    private func runSettleIntoCrate(scale _: CGFloat) {
        guard let lay = pendingSettleLayout else { return }
        pendingSettleLayout = nil

        let metrics = SavedCrate2DLayout.metrics(forCrateWidth: lay.crateWidth)
        let settleTarget = CGSize(
            width: 0,
            height: metrics.discLandedCenter.y - metrics.discRestCenter.y
        )

        withAnimation(.easeOut(duration: CrateDropAnimationSpec.windUpDuration)) {
            settlingScale = CrateDropAnimationSpec.windUpScale
            settlingTiltX = CrateDropAnimationSpec.windUpTiltX
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + CrateDropAnimationSpec.windUpDuration) {
            withAnimation(.interpolatingSpring(
                stiffness: CrateDropAnimationSpec.flipSpringStiffness,
                damping: CrateDropAnimationSpec.flipSpringDamping
            )) {
                vinylDragOffset = settleTarget
                settlingScale = CrateDropAnimationSpec.landedScale
                settlingTiltX = CrateDropAnimationSpec.landedTiltX
                settlingTiltY = CrateDropAnimationSpec.landedTiltY
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + CrateDropAnimationSpec.finishSettlingDelaySeconds) {
            vm.finishCrateDropSettling()
        }
    }

    // MARK: - Sheet chrome

    private func sheetShape(scale s: CGFloat) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: FigmaTheme.Library.sheetCorner * s,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: FigmaTheme.Library.sheetCorner * s,
            style: .continuous
        )
    }

    private func headerTotalHeight(scale s: CGFloat) -> CGFloat {
        let padTop = max(6 * s, c.headerPadding * s * 0.5)
        let padBottom = 6 * s
        let rowH = c.headerRowHeight * s
        let gap = max(10 * s, c.headerInnerGap * s)
        let divH = c.dividerHeight * s
        return padTop + rowH + gap + divH + padBottom
    }

    private func dropHereHeader(scale s: CGFloat) -> some View {
        let rowH = c.headerRowHeight * s

        let titleCopy: String = {
            switch vm.crateSavePhase {
            case .success:
                return "saved"
            case .presenting, .expanded, .settling:
                return "drop here"
            case .idle:
                return ""
            }
        }()

        return VStack(spacing: max(10 * s, c.headerInnerGap * s)) {
            ZStack {
                HStack(alignment: .center, spacing: 0) {
                    Image(FigmaImage.cratesLogo)
                        .renderingMode(.original)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: c.logoWidth * s, height: c.logoHeight * s, alignment: .leading)
                        .accessibilityLabel("Press")

                    Spacer(minLength: 0)

                    Button {
                        vm.closeCrateDropSheetChrome()
                    } label: {
                        Image(FigmaImage.cratesClose)
                            .renderingMode(.original)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: c.closeButtonSize * s, height: c.closeButtonSize * s)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.crateSavePhase == .settling)
                    .accessibilityLabel(vm.crateSavePhase == .success ? "Close after save" : "Cancel save to crate")
                    .accessibilityIdentifier("crate.drop.cancel")
                }
                .frame(height: rowH)

                Text(titleCopy)
                    .font(FigmaFont.libraryTitle(18 * s))
                    .foregroundStyle(FigmaTheme.textDark.opacity(vm.crateSavePhase == .success ? 1 : 0.88))
                    .allowsHitTesting(false)
                    .opacity(titleCopy.isEmpty ? 0 : 1)
            }
            .padding(.horizontal, 20 * s)

            Rectangle()
                .fill(FigmaTheme.textDark.opacity(0.75))
                .frame(height: max(2, c.dividerHeight * s))
                .padding(.horizontal, 20 * s)
        }
        .padding(.top, 6 * s)
        .padding(.bottom, 6 * s)
    }

    // MARK: - Body (crate + vinyl)

    private func sheetBody(contentHeight: CGFloat, scale s: CGFloat, fullWidth: CGFloat) -> some View {
        let crateWidth = min(fullWidth - 40 * s, 280 * s)
        let metrics = SavedCrate2DLayout.metrics(forCrateWidth: crateWidth)
        let discDiameter = metrics.discDiameter
        let vinylDragEnabled =
            vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded
        let isSettlingOrSaved = vm.crateSavePhase == .settling || vm.crateSavePhase == .success
        let discScale = isSettlingOrSaved ? settlingScale : 1

        return ZStack(alignment: .top) {
            if vm.crateSavePhase != .idle {
                SavedCrate2DScene(
                    crateWidth: crateWidth,
                    discOffset: vinylDragOffset,
                    discScale: discScale,
                    discHitPadding: 44 * s,
                    dragEnabled: vinylDragEnabled,
                    onDragChanged: { value in
                        handleDiscDragChanged(value, metrics: metrics)
                    },
                    onDragEnded: { value in
                        handleDiscDragEnded(value, metrics: metrics, crateWidth: crateWidth)
                    },
                    disc: {
                        crateDiscContent(
                            scale: s,
                            discDiameter: discDiameter
                        )
                    }
                )
                .padding(.top, max(8 * s, contentHeight * 0.04))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .accessibilityLabel("Drag disc into crate opening to save")
                .accessibilityHint("Drag up into the crate, flick up, or tap disc when over the opening.")
                .accessibilityIdentifier("crate.drop.vinyl")
            }
        }
        .frame(height: contentHeight)
    }

    private func handleDiscDragChanged(_ value: DragGesture.Value, metrics: SavedCrate2DLayout.Metrics) {
        guard vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded else { return }
        discDragActive = true
        let now = Date()
        if let (t, prev) = lastDragSample {
            let dt = max(0.012, now.timeIntervalSince(t))
            dragVelocityY = CGFloat((value.translation.height - prev.height) / dt)
        }
        lastDragSample = (now, value.translation)

        vinylDragOffset = CGSize(
            width: value.translation.width,
            height: value.translation.height
        )

        let center = metrics.discCenter(offset: vinylDragOffset)
        let inside = metrics.forgivingDropZone.contains(center)
        if inside != hoveringOpening {
            hoveringOpening = inside
            if inside { vm.impact(.light) }
        }
    }

    private func handleDiscDragEnded(
        _ value: DragGesture.Value,
        metrics: SavedCrate2DLayout.Metrics,
        crateWidth: CGFloat
    ) {
        lastDragSample = nil
        discDragActive = false
        defer {
            dragVelocityY = 0
            hoveringOpening = false
        }
        guard vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded else {
            vinylDragOffset = .zero
            return
        }

        let center = metrics.discCenter(offset: vinylDragOffset)
        let inDropZone = metrics.forgivingDropZone.contains(center)
        let predKick = value.predictedEndTranslation.height - value.translation.height
        let flickUpHard =
            (predKick < -40 && value.translation.height < -8)
            || (dragVelocityY < -240 && value.translation.height < -12)
        let flickUpAssist = metrics.flickAssistZone.contains(center)
            && predKick < -18
            && value.translation.height < -10
            && dragVelocityY < -140
        let liftedEnough = value.translation.height < -(metrics.discDiameter * 0.35)

        if inDropZone || flickUpHard || flickUpAssist || liftedEnough {
            pendingSettleLayout = CrateSettleLayout(crateWidth: crateWidth, discDiameter: metrics.discDiameter)
            vm.commitCrateDrop(at: dropIndex)
        } else {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                vinylDragOffset = .zero
            }
        }
    }

    @ViewBuilder
    private func crateDiscContent(
        scale s: CGFloat,
        discDiameter: CGFloat
    ) -> some View {
        let vinylDragEnabled =
            vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded
        let isSettlingOrSaved = vm.crateSavePhase == .settling || vm.crateSavePhase == .success
        let dragYaw = discDragActive && vinylDragEnabled && !isSettlingOrSaved ? -8.0 : 0.0
        let flipTiltX = isSettlingOrSaved ? settlingTiltX : (hoveringOpening ? -6 : 0)
        let flipTiltY = isSettlingOrSaved ? settlingTiltY : dragYaw

        draggableVinyl(scale: s, diameter: discDiameter)
            .crateDiscCardFlip(tiltX: flipTiltX, tiltY: flipTiltY)
            .modifier(CrateDiscIdlePulse(
                phase: vm.crateSavePhase,
                isDragging: discDragActive,
                isPlaying: vm.isPlaying,
                isHeroJewelCase: false,
                playbackAngle: vm.cdAngle
            ))
            .allowsHitTesting(false)
    }

    private func vinylDisplayDiameter(scale s: CGFloat) -> CGFloat {
        vm.crateSaveFromHero ? min(204 * s, 228) : min(184 * s, 208)
    }

    @ViewBuilder
    private func draggableVinyl(scale s: CGFloat, diameter: CGFloat) -> some View {
        let idx = dropIndex
        FigmaVinylView(
            sleeveIndex: idx,
            discArtwork: vm.crateSaveFromHero ? vm.heroDiscArtwork : vm.crateDiscArtwork(for: idx),
            labelColor: vm.crateAccentColor(for: idx),
            rotation: vm.isPlaying ? vm.cdAngle : 0,
            cellSize: diameter
        )
    }

    private func scrimOpacity(sheetHeight: CGFloat, screenHeight: CGFloat) -> Double {
        let p = min(1, sheetHeight / (screenHeight * 0.92))
        return 0.26 + 0.28 * p
    }

    private func scheduleExpandIfPresenting() {
        expandTask?.cancel()
        guard vm.crateSavePhase == .presenting else { return }
        expandTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 55_000_000)
            guard !Task.isCancelled, vm.crateSavePhase == .presenting else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                sheetDetent = .drop
            }
            try? await Task.sleep(nanoseconds: 395_000_000)
            guard !Task.isCancelled, vm.crateSavePhase == .presenting else { return }
            vm.crateDropSheetDidFinishExpanding()
        }
    }
}

// MARK: - Idle motion on the lifted disc

private struct CrateDiscIdlePulse: ViewModifier {
    let phase: CrateSavePhase
    let isDragging: Bool
    let isPlaying: Bool
    let isHeroJewelCase: Bool
    let playbackAngle: Double

    func body(content: Content) -> some View {
        if phase == .expanded && !isDragging {
            /// Hero jewel already reads “lifted”; bob/sway looked like unmotivated floating on the sheet.
            if isHeroJewelCase {
                content
                    .shadow(color: .black.opacity(0.13), radius: 8, x: 0, y: 5)
            } else {
                TimelineView(.animation(minimumInterval: 1 / 55)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let bob = sin(t * 2.55) * 3.8 + cos(t * 1.82) * 1.35
                    let sway = sin(t * 1.05) * 1.85
                    let spinBoost = isPlaying ? playbackAngle * 0.12 : sway * 2.9
                    content
                        .offset(y: bob)
                        .rotationEffect(.degrees(spinBoost))
                        .shadow(color: .black.opacity(0.1 + bob * 0.004), radius: 10 + abs(bob) * 0.15, y: 8 + bob * 0.12)
                }
            }
        } else if phase == .settling || phase == .success {
            content
                .shadow(color: .black.opacity(0.15), radius: 14, y: 11)
        } else {
            content
                .shadow(color: .black.opacity(0.1), radius: 10, y: 8)
        }
    }
}

private enum CrateDropSheetSpace {
    static let name = SavedCrate2DLayout.coordinateSpaceName
}
