import SwiftUI

// MARK: - FigmaPlayerLayout
//
// Two-section contract (`305:2651`):
//
//   48 pt top safe area + 8 pt inset below Dynamic Island
//   + hero content (CD `305:2722` + 8 gap + meta strip) — tight, no tail
//   + 20 pt strict white gap (#FFFFFF)
//   + bottom panel slot (fixed height, control centre slides inside)

enum FigmaPlayerLayout {
    struct Metrics {
        let topPadding: CGFloat
        let heroContentHeight: CGFloat
        let sectionGap: CGFloat
        let panelSlotHeight: CGFloat
        let bottomClearance: CGFloat
        let spacing: FigmaResponsiveSpacing
        let tier: FigmaDeviceTier
        let profile: FigmaLayoutProfile
        let scale: CGFloat
        let cardWidth: CGFloat
        let collapsedPanelHeight: CGFloat
        let expandedPanelHeight: CGFloat
        /// How far the full-height panel translates down at full reveal.
        let maxPanelSlide: CGFloat

        var heroStackHeight: CGFloat { heroContentHeight }
        var totalHeight: CGFloat { topPadding + heroContentHeight + sectionGap + panelSlotHeight }
    }

    static func metrics(
        viewportWidth: CGFloat,
        viewportHeight: CGFloat,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat
    ) -> Metrics {
        let tier = FigmaDeviceTier.resolve(width: viewportWidth, height: viewportHeight)
        let profile = FigmaLayoutProfile.resolve(viewportWidth: viewportWidth, viewportHeight: viewportHeight)
        let spacing = FigmaResponsiveSpacing.resolve(
            tier: tier,
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            safeAreaTop: safeAreaTop,
            safeAreaBottom: safeAreaBottom
        )
        let scale = spacing.scale
        let topInset = max(safeAreaTop, FigmaTopHalf.heroSafeAreaTop)
        let topPadding = topInset + spacing.heroTopPadding
        let heroContent = FigmaTopHalf.contentStackHeight * scale
        let gap = FigmaTheme.heroToPanelGap
        let collapsedH = FigmaTheme.panelCollapsedH * scale

        let panelSlot = max(
            collapsedH,
            viewportHeight - topPadding - heroContent - gap
        )
        /// Panel always fits the slot — avoids cropping SHUFFLE/REPEAT on compact phones.
        let expandedH = panelSlot
        let maxSlide = max(0, panelSlot - collapsedH)

        return Metrics(
            topPadding: topPadding,
            heroContentHeight: heroContent,
            sectionGap: gap,
            panelSlotHeight: panelSlot,
            bottomClearance: safeAreaBottom + FigmaTheme.homeIndicatorClearance,
            spacing: spacing,
            tier: tier,
            profile: profile,
            scale: scale,
            cardWidth: min(viewportWidth, FigmaTheme.designWidth),
            collapsedPanelHeight: collapsedH,
            expandedPanelHeight: expandedH,
            maxPanelSlide: maxSlide
        )
    }
}
