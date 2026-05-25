import SwiftUI

// MARK: - FigmaSheetTopGroove
//
// Figma `314:3508` / `332:4642` — `Rectangle 15153`, 182 × 12 pt, flush to the
// top edge of the bottom sheet. Replaces the old metallic pull-tab pill.

struct FigmaSheetTopGroove: View {
    var scale: CGFloat = 1

    static let nativeWidth: CGFloat = 182
    static let nativeHeight: CGFloat = 12

    var body: some View {
        FigmaSheetGrooveShape()
            .fill(FigmaTheme.sheetGrooveFill)
            .frame(width: Self.nativeWidth * scale, height: Self.nativeHeight * scale)
            .frame(maxWidth: .infinity)
    }
}

/// Vector path from Figma `Rectangle 15153` (viewBox 0 0 182 12).
private struct FigmaSheetGrooveShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 182
        let sy = rect.height / 12

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * sx, y: y * sy)
        }

        var path = Path()
        path.move(to: p(0, 0))
        path.addLine(to: p(182, 0))
        path.addLine(to: p(178.45, 3.74454))
        path.addCurve(
            to: p(159.25, 12),
            control1: p(173.455, 9.01492),
            control2: p(166.512, 12)
        )
        path.addLine(to: p(22.75, 12))
        path.addCurve(
            to: p(0, 0),
            control1: p(8.5454, 9.01492),
            control2: p(3.54952, 3.74455)
        )
        path.closeSubpath()
        return path
    }
}

#Preview("314:3508 — sheet groove") {
    VStack(spacing: 0) {
        FigmaSheetTopGroove(scale: 1)
        Rectangle()
            .fill(FigmaTheme.panelGrey)
            .frame(height: 120)
    }
    .frame(width: 402)
    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
}
