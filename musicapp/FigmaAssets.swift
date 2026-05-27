import Foundation

/// Bundled asset names under `Assets.xcassets/figma` (from Figma nodes 305:3130, 305:3150, 305:3451).
enum FigmaImage {
    static let cdDisc = "cd_disc"
    static let cdCoverArt = "cd_cover_art"
    /// Figma `360:2859` — slides left; uses cover art until a case-only export lands.
    static let cdCaseTray = "cd_cover_art"
    static let cdCaseSpine = "cd_case_spine"
    static let asterisk = "figma_asterisk"
    static let cratesLogo = "crates_logo"   // Figma `305:2745` Press wordmark (PNG)
    static let cratesClose = "crates_close" // Figma `305:2745` bordered X (SVG)
    static let cratesStripAsterisk = "crates_asterisk"
    /// Saved-crate PNG (green lattice crate — cropped from design reference).
    static let savedCrateGreen = "saved_crate_green"

    static let vinylDiskBase = "vinyl_disk_base"
    static let vinylLabelPlaceholder = "vinyl_disk_label_placeholder"
    static let vinylSpindle = "vinyl_spindle"
    static let vinylLabelFull = "vinyl_label_full"

    static func vinylSleeve(_ index: Int) -> String { "vinyl_sleeve_\(max(0, min(4, index)))" }

    static let panelDragHandle = "panel_drag_handle"
    static let dialA2 = "dial_a2"
    static let dialCenter = "dial_center"
    static let jamLeftRail = "jam_left_rail"
    static let jamArrowRight = "jam_arrow_right"
    static let knobOuter = "knob_outer"
    static let knobShadowCore = "knob_shadow_core"
    static let knobTactile = "knob_tactile"
    static let volChevron = "vol_chevron"
    static let volSliderTrack = "vol_slider_track"

    static func onboardingScreen(_ index: Int) -> String {
        "onboarding_s\(max(1, min(6, index)))"
    }
}
