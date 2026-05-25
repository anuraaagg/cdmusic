import SwiftUI
import UIKit

/// Design tokens extracted from Figma section 305:3301 (402pt reference width).
enum FigmaTheme {
    static let jamBarGrey = Color(red: 215 / 255, green: 215 / 255, blue: 214 / 255) // #d7d7d6-ish JAM pillar
    static let jamCapFill = Color(red: 213 / 255, green: 215 / 255, blue: 214 / 255) // #d5d7d6 Left-JAM (305:3385)
    static let jamCapTextMuted = Color(red: 219 / 255, green: 221 / 255, blue: 218 / 255) // #dbddda
    static let panelGrey = Color(red: 215 / 255, green: 217 / 255, blue: 217 / 255) // #d7d9d9
    static let crateInner = Color(red: 244 / 255, green: 244 / 255, blue: 244 / 255) // #f4f4f4
    static let hairlineBorder = Color(red: 34 / 255, green: 34 / 255, blue: 32 / 255) // ~#222220
    static let textDark = Color(red: 13 / 255, green: 12 / 255, blue: 10 / 255) // #0d0c0a
    static let orangeAccent = Color(red: 234 / 255, green: 43 / 255, blue: 7 / 255) // VOL #ea2b07
    /// Figma `314:3508` / `332:4642` drag groove fill.
    static let sheetGrooveFill = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x1E / 255)

    /// JAM status cluster (`332:4653`) — overlapping pills, no stroke.
    static let jamPillFill = Color(red: 248 / 255, green: 247 / 255, blue: 244 / 255) // #f8f7f4 surface/primary
    static let jamStatusText = Color(red: 0.05, green: 0.05, blue: 0.04)
    static let jamCounterText = Color(red: 8 / 255, green: 8 / 255, blue: 8 / 255) // #080808

    /// Figma `305:2722` — outer layout slot for the jewel case (340 @402 reference).
    static let heroCDSize: CGFloat = 340
    static let heroMetaStripH: CGFloat = 38
    static let heroMetaGap: CGFloat = 8
    static let designWidth: CGFloat = 402
    /// Figma `305:3025` artboard height (hero 422 + panel 452).
    static let designHeight: CGFloat = 874

    /// Apple HIG minimum touch target — meta strip hit areas extend to this height.
    static let minTouchTarget: CGFloat = 44
    /// Extra clearance above the home-indicator safe area for cream-panel controls.
    static let homeIndicatorClearance: CGFloat = 8
    /// Strict white band between hero meta strip and control panel (`305:2651`).
    static let heroToPanelGap: CGFloat = 20

    /// Figma `305:2722` — CD jewel case interior measurements.
    enum CD3052722 {
        static let discWidth: CGFloat = 269.62
        static let discHeight: CGFloat = 270.979
        static let caseWidth: CGFloat = 309.06
        static let caseHeight: CGFloat = 302.6
        static let spineWidth: CGFloat = 8.84
        static let spineHeight: CGFloat = 48.79
        static let spineOffsetX: CGFloat = 14.62
        static let spineOffsetY: CGFloat = 143.48
    }

    /// Scale for sub-402 pt widths only; never upscale past 1.0 on Pro / Pro Max.
    static func layoutScale(for viewportWidth: CGFloat) -> CGFloat {
        let raw = viewportWidth / designWidth
        return max(0.82, min(1.0, raw))
    }

    /// Snap to the physical pixel grid (avoids blurry 1 pt hairlines on 3× displays).
    static func snapToPixel(_ value: CGFloat) -> CGFloat {
        let scale = UIScreen.main.scale
        return (value * scale).rounded() / scale
    }

    /// Figma node `332:4647` toolbar — numbers are design pixels @402pt logical.
    enum JamToolbar {
        /// `332:4648` / `332:4658` — end caps and dial row are **64** pt tall (not 66).
        static let rowHeight: CGFloat = 64
        static let railWidth: CGFloat = 31.2
        static let railCorner: CGFloat = 14.4
        static let railLabelFont: CGFloat = 17.6
        static let railLabelBoxW: CGFloat = 22
        static let railLabelBoxH: CGFloat = 38
        static let railLabelOffsetX: CGFloat = 2.8
        static let railLabelOffsetY: CGFloat = 12.8
        static let dialPadding: CGFloat = 9.143
        static let dialBoxCorner: CGFloat = 7.314
        static let dialSize: CGFloat = 45.714
        /// Figma `332:4654` — fixed pill width before overlap (`w-[192px]`).
        static let statusPillWidth: CGFloat = 192
        /// Figma `332:4654` applies `mr-[-16px]` so the counter tucks under the status curve.
        static let pillsVisualOverlap: CGFloat = 16
        static let statusFont: CGFloat = 22
        static let pillHPad: CGFloat = 24
        static let pillVPad: CGFloat = 20
        static let pillCorner: CGFloat = 48
        static let counterFont: CGFloat = 16
        static let counterLineHeight: CGFloat = 24
        static let clusterGapMin: CGFloat = 10
        /// Dial plate + status pills share this height (`332:4653` cluster).
        static var innerClusterHeight: CGFloat { dialSize + dialPadding * 2 }
        /// PNGs are ~2× exports — horizontal bleed only; height matches `innerClusterHeight`.
        static let railAssetScale: CGFloat = 2
        static let railImageWidthBleed: CGFloat = 36 / railWidth      // ≈ 1.154
    }

    /// Figma `305:2741` / `305:3150` CRATES card.
    enum Crate {
        /// Outer grey shell inset (`305:2741` `p-[12px]`).
        static let outerPadding: CGFloat = 12
        static let innerRadius: CGFloat = 28
        /// Inner cream block height @402 (`305:2742` `h-[430px]`).
        static let innerContentHeight: CGFloat = 430
        static let innerStackGap: CGFloat = 12
        /// Header cream block (`305:2744` `p-[16px]` · `gap-[8px]`).
        static let headerPadding: CGFloat = 16
        static let headerInnerGap: CGFloat = 8
        static let dividerHeight: CGFloat = 2
        /// Body block (`305:2755` `gap-[16px]` · `pb-[24px]`).
        static let bodySectionGap: CGFloat = 16
        static let bodyBottomPadding: CGFloat = 24
        static let vinylSide: CGFloat = 200
        static let vinylGap: CGFloat = 6.154
        /// Song strip (`305:2794` `w-[362px]`).
        static let stripWidth: CGFloat = 362
        static let stripCellPadding: CGFloat = 12
        static let stripIconGlyphSize: CGFloat = 14
        static let closeButtonSize: CGFloat = 24
        static let closeBorderWidth: CGFloat = 0.32
        static let logoWidth: CGFloat = 48
        static let logoHeight: CGFloat = 20
        static let titleFontSize: CGFloat = 18
    }

    /// Figma node `332:4641` — full open control sheet @402pt wide.
    static let panelCornerRadius: CGFloat = 40
    /// Full expanded panel: collapsed chrome + gap + cream interior (332 pt @ 132 knob).
    static let panelExpandedH: CGFloat = 464
    /// Gap between chrome block and cream (`332:4641` root `gap-[8px]`).
    static let sheetBlockGap: CGFloat = 8
    /// Padding from groove block to JAM row (`332:4643` — after pull-tab removal).
    static let sheetGrooveToJamPadding: CGFloat = 12
    /// Drag groove (`332:4642` / `314:3508`).
    static let dragGrooveHeight: CGFloat = 12
    /// JAM row height (`332:4647`).
    static let jamRowHeight: CGFloat = 64
    /// JAM chrome block below the groove: pt 12 + JAM 64.
    static var sheetChromeFrameHeight: CGFloat { sheetGrooveToJamPadding + jamRowHeight }
    /// Collapsed chrome: groove 12 + gap 8 + JAM block 76 = **96**.
    static var panelCollapsedH: CGFloat { dragGrooveHeight + sheetBlockGap + sheetChromeFrameHeight }

    /// Cream panel (`332:4661`) interior rhythm — max values.
    static let creamPanelHPadding: CGFloat = 20
    /// `332:4662` transport row sits 31 pt below cream origin.
    static let creamPanelTopPadding: CGFloat = 31
    static let creamPanelBottomPadding: CGFloat = 31
    /// `332:4661` `gap-[32px]` between transport row and PREV/NEXT grid.
    static let creamPanelSectionGap: CGFloat = 32
    /// Bare cream interior without flex slack: 31 + 132 + 32 + 106 + 31.
    static var creamPanelBareHeight: CGFloat {
        creamPanelTopPadding + transportRowHeight + creamPanelSectionGap + buttonGridHeight + creamPanelBottomPadding
    }
    /// Compact-tier cream minimum (132 transport + 14 gap + 106 grid + 8 bottom).
    static let creamPanelCompactBareHeight: CGFloat = transportRowHeight + 14 + buttonGridHeight + 8
    static var creamPanelContentHeight: CGFloat { creamPanelBareHeight }

    /// Jog wheel platter — SVG `337:5621` / `332:4666` (**132 × 132** pt).
    static let transportRowHeight: CGFloat = 132
    static let jogWheelDiameter: CGFloat = 132
    /// Square PLAY/PAUSE column (`310:3476`) — 54.34 × 119.321 pt.
    static let playPauseColumnWidth: CGFloat = 54.34
    static let playPauseGap: CGFloat = FigmaSquareButton.columnGap         // 11.321
    static let playPauseColumnHeight: CGFloat = FigmaSquareButton.columnHeight // 119.321

    /// Half-button grid (`305:3416`): 48 + 10 + 48.
    static let buttonGridRowGap: CGFloat = 10
    static let buttonGridHeight: CGFloat = 106

    /// Figma `301:2340` — library bottom sheet.
    enum Library {
        static let sheetCorner: CGFloat = 40
        static let headerHPadding: CGFloat = 16
        static let contentHPadding: CGFloat = 20
        static let stripWidth: CGFloat = 362
        static let stripHeight: CGFloat = 38
        static let rowHeight: CGFloat = 36
        static let minSheetHeight: CGFloat = 180
        static let navButtonSize: CGFloat = 32
    }

    static func geoScale(_ geoWidth: CGFloat) -> CGFloat { geoWidth / designWidth }
}

// MARK: - Typography (Figma → Google Fonts + fallbacks)

enum FigmaFont {
    /// Doto (monospace / “Doto Mono”) — JAM status pill; `wght=400`, square dots (`ROND=0`) in `fetch_google_fonts.py`.
    static func status(_ size: CGFloat) -> Font {
        .custom(GoogleFontName.dotoMono, size: size)
    }

    /// Roboto Mono — track counter (`1-68`).
    static func counter(_ size: CGFloat) -> Font {
        .custom(GoogleFontName.robotoMonoRegular, size: size)
    }

    /// Sometype Mono — mono labels / transport (uses Bold file for heavier weights).
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let heavier: Set<Font.Weight> = [.medium, .semibold, .bold, .heavy, .black]
        let ps = heavier.contains(weight)
            ? GoogleFontName.sometypeMonoBold
            : GoogleFontName.sometypeMonoRegular
        return Font.custom(ps, size: size)
    }

    /// Red Hat Mono — PAUSE key asterisk.
    static func redHatMono(_ size: CGFloat) -> Font {
        .custom(GoogleFontName.redHatMonoRegular, size: size)
    }

    /// Gothic A1 SemiBold — JAM rail ornament.
    static func jamRail(_ size: CGFloat) -> Font {
        .custom(GoogleFontName.gothicA1Semibold, size: size)
    }

    /// Doto Bold — LIBRARY sheet title (`301:2352`).
    static func libraryTitle(_ size: CGFloat) -> Font {
        .custom(GoogleFontName.dotoMono, size: size)
    }

    /// Inter Regular — VOL label.
    static func vol(_ size: CGFloat) -> Font {
        .custom(GoogleFontName.interRegular, size: size)
    }
}

extension FigmaTheme {
    static func monoMeta(_ size: CGFloat = 12) -> Font { FigmaFont.mono(size) }
    static func jamStatus(_ size: CGFloat = 22) -> Font { FigmaFont.status(size) }
    static func cratesTitle(_ size: CGFloat = 18) -> Font { FigmaFont.mono(size, weight: .heavy) }
}
