import SwiftUI

// MARK: - FigmaCrateView
//
// Figma `305:2741` outer shell · `305:2742` inner cream · `305:2743` header.
// Same card slot as the control centre (`305:3451` / `305:3150`).

/// CRATES layer — always under the draggable control panel in the bottom Z-stack.
struct FigmaCrateView: View {
    @ObservedObject var vm: MusicPlayerViewModel
    var availableHeight: CGFloat? = nil
    /// Height of the control panel overlay (JAM chrome) — content sits above this.
    var jamBarReserve: CGFloat = 0
    var cardWidth: CGFloat = FigmaTheme.designWidth
    var scale: CGFloat = 1
    var tier: FigmaDeviceTier = .large
    var onCollapsePanel: () -> Void = {}

    private var c: FigmaTheme.Crate.Type { FigmaTheme.Crate.self }
    private var s: CGFloat { scale }

    private var outerPad: CGFloat { c.resolvedOuterPadding(tier: tier) }

    private var vinylCell: CGFloat {
        c.vinylCellSize(cardWidth: cardWidth, scale: s, tier: tier)
    }

    private var effectiveHeight: CGFloat {
        availableHeight ?? FigmaTheme.panelExpandedH * s
    }

    var body: some View {
        VStack(spacing: 0) {
            innerCreamBlock
                .padding(.horizontal, outerPad)
                .padding(.top, outerPad)
                .padding(.bottom, max(outerPad, jamBarReserve))
        }
        .frame(height: effectiveHeight, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(FigmaTheme.panelGrey)
        .overlay(alignment: .top) {
            if let msg = vm.saveToastMessage {
                Text(msg)
                    .font(.custom("Helvetica", size: 12 * s).weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14 * s)
                    .padding(.vertical, 8 * s)
                    .background(Color.black.opacity(0.82))
                    .clipShape(Capsule())
                    .padding(.top, 12 * s)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Inner cream (`305:2742`)

    private var innerCreamBlock: some View {
        VStack(spacing: c.innerStackGap * s) {
            crateHeader

            VStack(spacing: c.bodySectionGap * s) {
                if vm.crateSavePhase != .idle { dropZone }
                carousel
                songStrip
            }
            .padding(.bottom, c.bodyBottomPadding * s)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: c.innerRadius * s, style: .continuous)
                .fill(FigmaTheme.crateInner)
        )
        .clipShape(RoundedRectangle(cornerRadius: c.innerRadius * s, style: .continuous))
    }


    private var crateHeader: some View {
        let saving = vm.crateSavePhase != .idle
        let morph = morphAmount

        return ZStack(alignment: .top) {
            FigmaCrateHeader(scale: s, onClose: {
                if saving { vm.cancelCrateSave() } else {
                    vm.impact(.light)
                    onCollapsePanel()
                }
            })
            .opacity(saving ? 0 : 1)

            if saving {
                HStack {
                    Spacer(minLength: 0)
                    CratesLogoMorphView(
                        morphProgress: morph,
                        savedCount: vm.savedCrateStore.count,
                        scale: s
                    )
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, c.headerPadding * s)
                .padding(.top, c.headerPadding * s)
            }
        }
    }

    private var morphAmount: CGFloat {
        switch vm.crateSavePhase {
        case .idle, .lifting: return vm.crateSavePhase == .lifting ? 0.25 : 0
        case .morphing: return 0.65
        case .dropReady, .settling: return 1
        }
    }

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12 * s, style: .continuous)
            .stroke(FigmaTheme.orangeAccent.opacity(0.55), lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 12 * s, style: .continuous)
                    .fill(FigmaTheme.orangeAccent.opacity(0.08))
            )
            .frame(height: 64 * s)
            .padding(.horizontal, outerPad)
            .opacity(vm.crateSavePhase == .dropReady ? 1 : 0.3)
            .animation(.easeInOut(duration: 0.25), value: vm.crateSavePhase)
    }

    // MARK: - Vinyl carousel (`305:2756`)

    @StateObject private var scrollMotion = CrateScrollMotionTracker()
    @State private var carouselViewportWidth: CGFloat = 0
    @State private var saveDragOffset: CGSize = .zero
    @State private var saveLiftIndex: Int?

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: c.vinylGap * s) {
                ForEach(0..<vm.vinylCarouselCount, id: \.self) { index in
                    let selected = vm.crateActiveIndex == index
                    let spinning = selected && vm.isPlaying
                    let parallax = scrollMotion.parallaxNorm(
                        index: index,
                        cellSize: vinylCell,
                        gap: c.vinylGap * s,
                        leadingPad: outerPad,
                        viewportWidth: carouselViewportWidth
                    )
                    crateVinylCell(
                        index: index,
                        selected: selected,
                        spinning: spinning,
                        parallax: parallax
                    )
                }
            }
            .padding(.horizontal, outerPad)
        }
        .coordinateSpace(name: CrateScrollSpace.name)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.x
        } action: { _, newOffset in
            scrollMotion.ingest(contentOffsetX: newOffset)
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { carouselViewportWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, width in
                        carouselViewportWidth = width
                    }
            }
        }
        .frame(height: vinylCell)
    }

    @ViewBuilder
    private func crateVinylCell(index: Int, selected: Bool, spinning: Bool, parallax: CGFloat) -> some View {
        let lifted = saveLiftIndex == index || vm.crateSaveDragIndex == index
        let liftScale: CGFloat = lifted ? 1.12 : 1

        CrateVinylRippleView(
            sleeveIndex: vm.crateSleeveIndex(for: index),
            discArtwork: vm.crateDiscArtwork(for: index),
            labelColor: vm.crateAccentColor(for: index),
            rotation: spinning ? vm.cdAngle : 0,
            cellSize: vinylCell,
            parallaxNorm: parallax,
            scrollVelocity: scrollMotion.velocityX,
            onTap: {
                guard vm.crateSavePhase == .idle else { return }
                vm.crateVinylTapped(at: index)
            }
        )
        .scaleEffect(liftScale)
        .rotation3DEffect(.degrees(lifted ? -10 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
        .offset(lifted ? saveDragOffset : .zero)
        .zIndex(lifted ? 10 : 0)
        .gesture(saveGesture(for: index))
    }

    private func saveGesture(for index: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .onEnded { _ in
                saveLiftIndex = index
                vm.beginCrateSave(at: index)
            }
            .simultaneously(with:
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        guard vm.crateSavePhase != .idle, vm.crateSaveDragIndex == index || saveLiftIndex == index else { return }
                        saveLiftIndex = index
                        saveDragOffset = value.translation
                    }
                    .onEnded { value in
                        guard vm.crateSaveDragIndex == index || saveLiftIndex == index else { return }
                        if vm.crateSavePhase == .dropReady, value.translation.height > 36 {
                            vm.commitCrateSave(at: index)
                        } else {
                            vm.cancelCrateSave()
                        }
                        saveLiftIndex = nil
                        saveDragOffset = .zero
                    }
            )
    }

    // MARK: - Song strip (`305:2794`)

    private var songStrip: some View {
        let border = FigmaTheme.hairlineBorder
        let title = vm.crateStripTitle(for: vm.crateActiveIndex)
        let iconCell = c.stripCellPadding * 2 + c.stripIconGlyphSize

        return HStack(spacing: 0) {
            FigmaAsterisk(color: .red)
                .frame(width: c.stripIconGlyphSize * s, height: c.stripIconGlyphSize * s)
                .frame(width: iconCell * s, height: FigmaTheme.heroMetaStripH * s)
                .overlay(Rectangle().stroke(border, lineWidth: FigmaTheme.snapToPixel(1)))

            Text(title)
                .font(.custom("Helvetica", size: 12 * s))
                .tracking(-0.96 * s)
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)
                .frame(height: FigmaTheme.heroMetaStripH * s)
                .padding(.horizontal, c.stripCellPadding * s)
                .overlay(alignment: .leading) {
                    Rectangle().fill(border).frame(width: FigmaTheme.snapToPixel(1))
                }
                .overlay(alignment: .trailing) {
                    Rectangle().fill(border).frame(width: FigmaTheme.snapToPixel(1))
                }
        }
        .frame(width: c.stripWidth * s, height: FigmaTheme.heroMetaStripH * s)
        .background(Color.white)
        .overlay(Rectangle().stroke(border, lineWidth: FigmaTheme.snapToPixel(1)))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - FigmaCrateHeader
//
// Figma `305:2743` / `305:2744` / `305:2745` — cream header inside the crate box.
// Row `305:2745`: Press logo (left) · CRATES title (centre) · bordered X (right).

struct FigmaCrateHeader: View {
    var scale: CGFloat = 1
    var onClose: () -> Void = {}

    private var c: FigmaTheme.Crate.Type { FigmaTheme.Crate.self }

    var body: some View {
        let s = scale
        let pad = c.headerPadding * s
        let rowH = c.headerRowHeight * s

        VStack(spacing: c.headerInnerGap * s) {
            ZStack {
                HStack(alignment: .center, spacing: 0) {
                    pressLogo(scale: s)
                        .frame(width: c.logoWidth * s, alignment: .leading)
                    Spacer(minLength: 0)
                    closeButton(scale: s)
                        .frame(width: c.logoWidth * s, alignment: .trailing)
                }
                .frame(height: rowH)

                Text("CRATES")
                    .font(FigmaFont.libraryTitle(c.titleFontSize * s))
                    .foregroundStyle(FigmaTheme.textDark)
                    .allowsHitTesting(false)
            }

            Rectangle()
                .fill(FigmaTheme.textDark.opacity(0.75))
                .frame(height: c.dividerHeight * s)
        }
        .padding(pad)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Figma `305:2745` — bundled `crates_logo` PNG (Press wordmark).
    private func pressLogo(scale s: CGFloat) -> some View {
        Image(FigmaImage.cratesLogo)
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: c.logoWidth * s, height: c.logoHeight * s, alignment: .leading)
            .accessibilityLabel("Press")
    }

    /// Figma `305:2745` — bundled `crates_close` SVG (24 pt bordered X).
    private func closeButton(scale s: CGFloat) -> some View {
        let box = c.closeButtonSize * s

        return Button(action: onClose) {
            Image(FigmaImage.cratesClose)
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: box, height: box)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close crates")
    }
}

#Preview("Crate — Figma 305:2741") {
    FigmaCrateView(vm: MusicPlayerViewModel(), availableHeight: 454, scale: 1)
        .frame(width: 402, height: 454)
}

#Preview("Crate header — 305:2743") {
    FigmaCrateHeader(scale: 1)
        .frame(width: 378)
        .background(FigmaTheme.crateInner)
}
