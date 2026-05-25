import SwiftUI

/// Root player layout: fixed CD hero, 20pt white gap, bottom panel slot with sliding control centre.
struct FigmaPlayerScreen: View {
    @ObservedObject var vm: MusicPlayerViewModel

    var body: some View {
        GeometryReader { geo in
            let safe = geo.safeAreaInsets
            let layout = FigmaPlayerLayout.metrics(
                viewportWidth: geo.size.width,
                viewportHeight: geo.size.height,
                safeAreaTop: FigmaTopHalf.heroSafeAreaTop,
                safeAreaBottom: safe.bottom
            )

            VStack(spacing: 0) {
                FigmaCDHeroView(vm: vm, spacing: layout.spacing)
                    .frame(height: layout.heroContentHeight, alignment: .top)
                    .frame(maxWidth: .infinity)

                Color.white
                    .frame(height: layout.sectionGap)
                    .accessibilityHidden(true)

                bottomCardStack(layout: layout)
                    .frame(height: layout.panelSlotHeight)
                    .opacity(vm.showLibrary ? 0 : 1)
                    .allowsHitTesting(!vm.showLibrary)
            }
            .padding(.top, layout.topPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                vm.updateFigmaLayoutScale(for: geo.size.width)
                vm.showControlCentre(animated: false)
            }
            .onChange(of: geo.size.width) { _, nw in vm.updateFigmaLayoutScale(for: nw) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .ignoresSafeArea(edges: [.top, .bottom])
    }

    /// Crate fills slot; control panel always full height and translates down to reveal crate.
    private func bottomCardStack(layout: FigmaPlayerLayout.Metrics) -> some View {
        let safeBottom = layout.bottomClearance - FigmaTheme.homeIndicatorClearance
        let slideY = (1 - vm.controlPanelRevealFraction) * layout.maxPanelSlide

        return ZStack(alignment: .top) {
            FigmaCrateView(
                vm: vm,
                availableHeight: layout.panelSlotHeight,
                jamBarReserve: layout.collapsedPanelHeight,
                cardWidth: layout.cardWidth,
                scale: layout.scale,
                tier: layout.tier,
                onCollapsePanel: { vm.showControlCentre() }
            )
            .allowsHitTesting(vm.controlPanelRevealFraction < 0.35)

            FigmaControlPanel(
                vm: vm,
                revealFraction: $vm.controlPanelRevealFraction,
                expandedHeight: layout.expandedPanelHeight,
                maxSlideDistance: layout.maxPanelSlide,
                slideOffset: slideY,
                safeAreaBottom: safeBottom,
                spacing: layout.spacing
            )
        }
        .frame(width: layout.cardWidth, height: layout.panelSlotHeight)
        .clipped()
        .background(FigmaTheme.panelGrey.ignoresSafeArea(edges: .bottom))
        .clipShape(
            RoundedRectangle(
                cornerRadius: FigmaTheme.panelCornerRadius * layout.scale,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.06), radius: 6 * layout.scale, y: 2 * layout.scale)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FigmaPlayerScreen(vm: MusicPlayerViewModel())
}

#Preview("Figma iPhone 17 — 402×874 pixel reference") {
    FigmaPlayerScreen(vm: MusicPlayerViewModel())
        .frame(width: FigmaTheme.designWidth, height: FigmaTheme.designHeight)
}

#Preview("Figma iPhone 17 — with safe areas") {
    FigmaPlayerScreen(vm: MusicPlayerViewModel())
        .frame(width: FigmaTheme.designWidth, height: FigmaTheme.designHeight)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 59)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 34)
        }
}

#Preview("332:4617 — iPhone 13/14 compact (390×844)") {
    FigmaPlayerScreen(vm: MusicPlayerViewModel())
        .frame(width: 390, height: 844)
}

#Preview("Tier small — iPhone SE (375×667)") {
    FigmaPlayerScreen(vm: MusicPlayerViewModel())
        .frame(width: 375, height: 667)
}

#Preview("Crate revealed — drag control panel down") {
    let vm = MusicPlayerViewModel()
    vm.controlPanelRevealFraction = 0
    return FigmaPlayerScreen(vm: vm)
        .frame(width: FigmaTheme.designWidth, height: FigmaTheme.designHeight)
}
