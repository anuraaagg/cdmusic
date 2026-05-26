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
    let fullWidth: CGFloat
    let contentHeight: CGFloat
    let opening: CGRect
    let bottomPad: CGFloat
    let vinylDiameter: CGFloat
}

struct FigmaCrateDropSheet: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @StateObject private var crateController = MilkCrateSceneController()

    @State private var sheetDetent: CrateDropSheetDetent = .peek
    @State private var vinylDragOffset: CGSize = .zero
    @State private var lastDragSample: (Date, CGSize)?
    @State private var dragVelocityY: CGFloat = 0
    @State private var hoveringOpening = false
    @State private var expandTask: Task<Void, Never>?
    @GestureState private var vinylDragActive = false
    /// Target layout when `commitCrateDrop` runs — feeds the settle spring.
    @State private var pendingSettleLayout: CrateSettleLayout?

    /// Disc scales down slightly as it “drops in”.
    @State private var settlingScale: CGFloat = 1
    /// Pitches the jewel toward the crate opening during the settle animation (flick / release in zone).
    @State private var settlingTiltX: Double = 0
    /// Hide the 2D jewel once the RealityKit sleeve spawns at the rim (no ghost disc).
    @State private var hideJewelAfterRimHandoff = false

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
                            hideJewelAfterRimHandoff = false
                            settlingScale = 1
                            settlingTiltX = 0
                            vinylDragOffset = .zero
                            crateController.updateSleeves(moments: vm.savedCrateStore.moments)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                crateController.updateSleeves(moments: vm.savedCrateStore.displayMoments)
                hideJewelAfterRimHandoff = false
                sheetDetent = .peek
                vinylDragOffset = .zero
                settlingScale = 1
                settlingTiltX = 0
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
                    hideJewelAfterRimHandoff = false
                    pendingSettleLayout = nil
                }
            }
        }
    }

    // MARK: - Settle pipeline

    private func runSettleIntoCrate(scale s: CGFloat) {
        guard let lay = pendingSettleLayout else { return }
        pendingSettleLayout = nil
        hideJewelAfterRimHandoff = false

        /// Show peers only — avoids a duplicate sleeve while the 2D jewel approaches the rim.
        crateController.showStackPriorToSaving(moments: vm.savedCrateStore.moments)

        let restBottom = lay.contentHeight - lay.bottomPad - lay.vinylDiameter * 0.5
        let restX = lay.fullWidth * 0.5
        let targetY = lay.opening.minY + lay.opening.height * 0.76 + 8 * s
        let target = CGPoint(x: lay.opening.midX, y: targetY)
        let settleTarget = CGSize(width: target.x - restX, height: target.y - restBottom)

        withAnimation(.easeOut(duration: 0.1)) {
            settlingScale = 1.035
            settlingTiltX = -5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(.interpolatingSpring(stiffness: 210, damping: 23)) {
                vinylDragOffset = settleTarget
                settlingScale = CrateDropAnimationSpec.jewelScalePeak
                settlingTiltX = CrateDropAnimationSpec.jewelTiltPeakDegrees
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(CrateDropAnimationSpec.jewelTweakDelaySeconds)) {
            withAnimation(.easeOut(duration: 0.12)) {
                settlingTiltX = CrateDropAnimationSpec.jewelTiltRestDegrees
                settlingScale = CrateDropAnimationSpec.jewelScaleRest
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(CrateDropAnimationSpec.crossRimDelaySeconds)) {
            hideJewelAfterRimHandoff = true
            if let m = vm.savedCrateStore.moments.first {
                crateController.insertSavingMomentAtFront(m)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(CrateDropAnimationSpec.finishSettlingDelaySeconds)) {
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
        let vinylDiameter = vinylDisplayDiameter(scale: s)
        let bottomPad = max(34 * s, 24) + FigmaTheme.homeIndicatorClearance + 6 * s
        let crateHPadding = 20 * s
        let opening = openingRect(
            contentWidth: fullWidth - crateHPadding * 2,
            contentHeight: contentHeight,
            scale: s,
            crateTopInset: 8 * s
        )
        /// Shift opening into full-width coords (opening was for inset crate column).
        let openingGlobal = opening.offsetBy(dx: crateHPadding, dy: 0)
        /// Easier commits than strict pixel overlap with RealityKit framing.
        let hitTestOpening = openingGlobal.insetBy(dx: -38, dy: -48)

        /// Drag is allowed as soon as the sheet is up (`.presenting`); waiting only for `.expanded` left a ~0.45s window where the disc ignored touches.
        let vinylDragEnabled =
            vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded

        return ZStack(alignment: .bottom) {
            VStack(spacing: 12 * s) {
                MilkCrateSceneView(
                    controller: crateController,
                    /// Never compete with the draggable vinyl sheet — crate flip gestures are unavailable here.
                    allowsInteraction: false
                )
                .frame(height: crateSceneHeight(contentHeight: contentHeight, scale: s))
                .padding(.horizontal, 6 * s)
            }
            /// RealityKit/`RealityView` can sit above overlapping vinyl in hit order on some layouts; sheet body ignores crate subtree for hits.
            .allowsHitTesting(false)
            .padding(.vertical, vm.crateSavePhase == .success ? 16 * s : 12 * s)
            .padding(.horizontal, crateHPadding)
            /// Bottom-anchored: reserve space for the resting disc under the crate opening.
            .padding(.bottom, bottomPad + vinylDiameter * 0.58 + 10 * s)
            .frame(maxWidth: .infinity)
            .zIndex(0)

            Group {
                if vm.crateSavePhase != .success {
                    draggableVinyl(scale: s, diameter: vinylDiameter)
                        .scaleEffect(vm.crateSavePhase == .settling ? settlingScale : 1)
                        .padding(.bottom, bottomPad)
                        .offset(vinylDragOffset)
                        .opacity(vm.crateSavePhase == .settling && hideJewelAfterRimHandoff ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(vm.crateSavePhase == .settling ? settlingTiltX : 0),
                            axis: (x: 1, y: 0, z: 0),
                            perspective: 0.55
                        )
                        .rotation3DEffect(
                            .degrees(vinylDragEnabled && vinylDragActive && vm.crateSavePhase != .settling ? -9 : 0),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.48
                        )
                        .modifier(CrateDiscIdlePulse(
                            phase: vm.crateSavePhase,
                            isDragging: vinylDragActive,
                            isPlaying: vm.isPlaying,
                            isHeroJewelCase: vm.crateSaveFromHero,
                            playbackAngle: vm.cdAngle
                        ))
                        /// Generous finger target independent of procedural layers / jewel alpha.
                        .contentShape(Circle())
                        .frame(width: vinylDiameter + 28 * s, height: vinylDiameter + 28 * s)
                        .gesture(
                            vinylDragGesture(
                                hitTestOpening: hitTestOpening,
                                settleOpening: opening,
                                vinylDiameter: vinylDiameter,
                                bottomPad: bottomPad,
                                contentSize: CGSize(width: fullWidth, height: contentHeight)
                            )
                        )
                        .simultaneousGesture(vinylTapCommitGesture(
                            hitTestOpening: hitTestOpening,
                            settleOpening: opening,
                            vinylDiameter: vinylDiameter,
                            bottomPad: bottomPad,
                            contentSize: CGSize(width: fullWidth, height: contentHeight)
                        ))
                        .allowsHitTesting(vinylDragEnabled && vm.crateSavePhase != .settling)
                }
            }
            .accessibilityLabel("Drag, flick up, or tap disc over opening to save")
            .accessibilityHint("Lift the disc into the crate opening until it overlaps, tap, flick up, or release.")
            .accessibilityIdentifier("crate.drop.vinyl")
            .allowsHitTesting(vm.crateSavePhase != .success)
            .zIndex(20)

        }
        .frame(height: contentHeight)
        .coordinateSpace(name: CrateDropSheetSpace.name)
    }

    private func crateSceneHeight(contentHeight: CGFloat, scale s: CGFloat) -> CGFloat {
        switch sheetDetent {
        case .peek:
            return min(92 * s, contentHeight * 0.52)
        case .drop:
            return max(
                contentHeight * 0.54,
                min(318 * s, screenRelativeCrateCap(contentHeight))
            )
        }
    }

    private func screenRelativeCrateCap(_ contentHeight: CGFloat) -> CGFloat {
        min(360, contentHeight * 0.62)
    }

    private func vinylDisplayDiameter(scale s: CGFloat) -> CGFloat {
        vm.crateSaveFromHero ? min(204 * s, 228) : min(184 * s, 208)
    }

    @ViewBuilder
    private func draggableVinyl(scale s: CGFloat, diameter: CGFloat) -> some View {
        let idx = dropIndex
        if vm.crateSaveFromHero {
            FigmaCDJewelCase(vm: vm, allowsInteraction: false)
                .frame(width: diameter, height: diameter)
        } else {
            CrateProceduralDropVinyl(
                discArtwork: vm.crateDiscArtwork(for: idx),
                labelColor: vm.crateAccentColor(for: idx),
                rotation: vm.isPlaying ? vm.cdAngle : 0,
                diameter: diameter
            )
        }
    }

    private func openingRect(
        contentWidth: CGFloat,
        contentHeight: CGFloat,
        scale s: CGFloat,
        crateTopInset: CGFloat
    ) -> CGRect {
        /// Crate-stack is bottom-anchored; zone is enlarged so disc center overlaps count as “in the opening.”
        let top = crateTopInset + contentHeight * 0.012
        let h = max(112 * s, contentHeight * 0.42)
        let inset = contentWidth * 0.045
        return CGRect(x: inset, y: top, width: contentWidth - 2 * inset, height: h)
    }

    private func vinylCenter(
        contentSize: CGSize,
        vinylDiameter: CGFloat,
        bottomPad: CGFloat,
        offset: CGSize
    ) -> CGPoint {
        CGPoint(
            x: contentSize.width * 0.5 + offset.width,
            y: contentSize.height - bottomPad - vinylDiameter * 0.5 + offset.height
        )
    }

    private func vinylDragGesture(
        hitTestOpening: CGRect,
        settleOpening: CGRect,
        vinylDiameter: CGFloat,
        bottomPad: CGFloat,
        contentSize: CGSize
    ) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(CrateDropSheetSpace.name))
            .updating($vinylDragActive) { _, state, _ in
                state = true
            }
            .onChanged { value in
                guard vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded else { return }
                let now = Date()
                if let (t, prev) = lastDragSample {
                    let dt = max(0.012, now.timeIntervalSince(t))
                    dragVelocityY = CGFloat((value.translation.height - prev.height) / dt)
                }
                lastDragSample = (now, value.translation)

                vinylDragOffset = CGSize(
                    width: value.translation.width * 0.78,
                    height: value.translation.height
                )

                let center = vinylCenter(
                    contentSize: contentSize,
                    vinylDiameter: vinylDiameter,
                    bottomPad: bottomPad,
                    offset: vinylDragOffset
                )
                let inside = hitTestOpening.contains(center)
                if inside != hoveringOpening {
                    hoveringOpening = inside
                    if inside { vm.impact(.light) }
                }
            }
            .onEnded { value in
                lastDragSample = nil
                defer {
                    dragVelocityY = 0
                    hoveringOpening = false
                }
                guard vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded else {
                    vinylDragOffset = .zero
                    return
                }

                let center = vinylCenter(
                    contentSize: contentSize,
                    vinylDiameter: vinylDiameter,
                    bottomPad: bottomPad,
                    offset: vinylDragOffset
                )
                let inDropZone = hitTestOpening.contains(center)
                /// Wider forgiving band above the rigid hit rect — catches upward flicks that don’t linger in the oval.
                let flickAssistZone = hitTestOpening.insetBy(dx: -18, dy: -52)
                let predKick = value.predictedEndTranslation.height - value.translation.height

                /// Upward flick: combine predicted overshoot + measured velocity (`DragGesture` undershoots fast snaps).
                let flickUpHard =
                    (predKick < -48 && value.translation.height < -10)
                    || (predKick < -85 && value.translation.height < -4)
                    || (dragVelocityY < -280 && value.translation.height < -16)
                    || (dragVelocityY < -520 && value.translation.height < -6)
                /// Softer flick when the gesture already crossed into the assist cone.
                let flickUpAssist = flickAssistZone.contains(center)
                    && predKick < -22
                    && value.translation.height < -14
                    && dragVelocityY < -155

                let flickUp = flickUpHard || flickUpAssist

                let index = dropIndex

                let layout = CrateSettleLayout(
                    fullWidth: contentSize.width,
                    contentHeight: contentSize.height,
                    opening: settleOpening,
                    bottomPad: bottomPad,
                    vinylDiameter: vinylDiameter
                )

                if inDropZone || flickUp {
                    pendingSettleLayout = layout
                    vm.commitCrateDrop(at: index)
                } else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        vinylDragOffset = .zero
                    }
                }
            }
    }

    /// Tap-to-save when the disc is already over the forgiving hit rect (matches drag release semantics).
    private func vinylTapCommitGesture(
        hitTestOpening: CGRect,
        settleOpening: CGRect,
        vinylDiameter: CGFloat,
        bottomPad: CGFloat,
        contentSize: CGSize
    ) -> some Gesture {
        TapGesture()
            .onEnded { _ in
                guard vm.crateSavePhase == .presenting || vm.crateSavePhase == .expanded else { return }
                let center = vinylCenter(
                    contentSize: contentSize,
                    vinylDiameter: vinylDiameter,
                    bottomPad: bottomPad,
                    offset: vinylDragOffset
                )
                guard hitTestOpening.contains(center) else { return }
                let layout = CrateSettleLayout(
                    fullWidth: contentSize.width,
                    contentHeight: contentSize.height,
                    opening: settleOpening,
                    bottomPad: bottomPad,
                    vinylDiameter: vinylDiameter
                )
                pendingSettleLayout = layout
                vm.impact(.light)
                vm.commitCrateDrop(at: dropIndex)
            }
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
    static let name = "crateDropSheet.body"
}
