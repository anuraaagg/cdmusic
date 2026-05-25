import SwiftUI

// MARK: - FigmaBottomSheetTopBar
//
// Legacy wrapper — chrome now lives directly on `FigmaControlPanel` to match
// Figma `314:3507` / `332:4641` (groove `314:3508` + JAM row). Kept so previews
// and call sites that still inject a JAM slot continue to compile.

struct FigmaBottomSheetTopBar<JamToolbar: View>: View {
    var scale: CGFloat = 1
    var sectionGap: CGFloat = FigmaTheme.sheetBlockGap
    @ViewBuilder var jamToolbar: () -> JamToolbar

    static var nativeHeight: CGFloat { FigmaTheme.panelCollapsedH - FigmaTheme.dragGrooveHeight }

    var body: some View {
        let s = scale

        jamToolbar()
            .frame(maxWidth: .infinity)
            .padding(.top, FigmaTheme.sheetGrooveToJamPadding * s)
            .padding(.bottom, sectionGap * s)
    }
}

#Preview("FigmaBottomSheetTopBar — 332:4643") {
    VStack(spacing: 0) {
        FigmaSheetTopGroove(scale: 1)
        FigmaBottomSheetTopBar(scale: 1) {
            FigmaJamToolbar(
                statusText: "not playing",
                counterText: "1-68",
                onDialTap: {}
            )
        }
    }
    .padding(.bottom, 24)
    .frame(width: 402)
    .background(FigmaTheme.panelGrey)
}
