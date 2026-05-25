import SwiftUI

// MARK: - FigmaResponsiveSpacing
//
// Spacing contract aligned to Figma `305:3451` on tall screens; compressed
// proportionally on compact tiers.

struct FigmaResponsiveSpacing {
    let tightness: CGFloat
    let scale: CGFloat
    let tier: FigmaDeviceTier

    static func resolve(
        tier: FigmaDeviceTier,
        viewportWidth: CGFloat,
        viewportHeight: CGFloat,
        safeAreaTop: CGFloat = 0,
        safeAreaBottom: CGFloat = 0
    ) -> FigmaResponsiveSpacing {
        let widthScale = viewportWidth / FigmaTheme.designWidth
        let scale: CGFloat = switch tier {
        case .small:   max(0.88, min(0.96, widthScale))
        case .compact: max(0.93, min(1.0, widthScale))
        case .large:   min(1.0, max(0.98, widthScale))
        }

        let tightness: CGFloat = switch tier {
        case .small:
            slackTightness(viewportHeight: viewportHeight, scale: scale,
                           safeAreaTop: safeAreaTop, safeAreaBottom: safeAreaBottom,
                           slackTarget: 60, floor: 0.08, ceiling: 0.75)
        case .compact:
            slackTightness(viewportHeight: viewportHeight, scale: scale,
                           safeAreaTop: safeAreaTop, safeAreaBottom: safeAreaBottom,
                           slackTarget: 80, floor: 0.15, ceiling: 0.85)
        case .large:
            1
        }

        return FigmaResponsiveSpacing(tightness: tightness, scale: scale, tier: tier)
    }

    private static func slackTightness(
        viewportHeight: CGFloat,
        scale: CGFloat,
        safeAreaTop: CGFloat,
        safeAreaBottom: CGFloat,
        slackTarget: CGFloat,
        floor: CGFloat,
        ceiling: CGFloat
    ) -> CGFloat {
        let heroBare = FigmaTopHalf.contentStackHeight + FigmaTopHalf.topInset + FigmaTheme.heroToPanelGap
        let panelBare = (FigmaTheme.panelCollapsedH + FigmaTheme.creamPanelCompactBareHeight) * scale
        let usableHeight = viewportHeight - safeAreaBottom
        let slack = max(0, usableHeight - heroBare - panelBare)
        let t = min(1, slack / slackTarget)
        return max(floor, t * ceiling)
    }

    // MARK: Hero — Figma `305:3026` / `305:3028`

    /// 8 pt below the status bar / Dynamic Island.
    var heroTopPadding: CGFloat { FigmaTopHalf.maxTopInset }

    /// No decorative tail — the 20 pt white gap is a separate layer in `FigmaPlayerScreen`.
    var heroDecorBottomPadding: CGFloat { 0 }

    // MARK: Sheet — `305:3451` root `gap-[8px]` + JAM `pt-[12px]`

    var sheetBlockGap: CGFloat { lerp(6, FigmaTheme.sheetBlockGap, tightness) * scale }

    var sheetGrooveToJamPadding: CGFloat {
        lerp(8, FigmaTheme.sheetGrooveToJamPadding, tightness) * scale
    }

    // MARK: Cream — `305:3398` `gap-[32px]` · `px-[20px]`

    var creamBottomPadding: CGFloat {
        switch tier {
        case .small:   return lerp(4, 8, tightness) * scale
        case .compact: return lerp(6, 12, tightness) * scale
        case .large:   return FigmaTheme.creamPanelBottomPadding * scale
        }
    }

    var creamSectionGap: CGFloat {
        lerp(14, FigmaTheme.creamPanelSectionGap, tightness) * scale
    }

    private func lerp(_ lo: CGFloat, _ hi: CGFloat, _ t: CGFloat) -> CGFloat {
        lo + (hi - lo) * Swift.min(Swift.max(t, 0), 1)
    }
}
