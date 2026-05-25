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
    var scale: CGFloat = 1
    var onCollapsePanel: () -> Void = {}

    private var c: FigmaTheme.Crate.Type { FigmaTheme.Crate.self }
    private var s: CGFloat { scale }

    private var vinylCell: CGFloat { c.vinylSide * s }

    private var effectiveHeight: CGFloat {
        availableHeight ?? FigmaTheme.panelExpandedH * s
    }

    var body: some View {
        let outerPad = c.outerPadding * s

        VStack(spacing: 0) {
            innerCreamBlock
                .padding(.horizontal, outerPad)
                .padding(.top, outerPad)
                .padding(.bottom, max(outerPad, jamBarReserve))
        }
        .frame(height: effectiveHeight, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(FigmaTheme.panelGrey)
    }

    // MARK: - Inner cream (`305:2742`)

    private var innerCreamBlock: some View {
        VStack(spacing: c.innerStackGap * s) {
            FigmaCrateHeader(scale: s, onClose: {
                vm.impact(.light)
                onCollapsePanel()
            })

            VStack(spacing: c.bodySectionGap * s) {
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

    // MARK: - Vinyl carousel (`305:2756`)

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: c.vinylGap * s) {
                ForEach(Array(CrateCatalog.entries.enumerated()), id: \.element.id) { index, crate in
                    let selected = vm.crateActiveIndex == index
                    let spinning = selected && vm.isPlaying
                    FigmaVinylView(
                        sleeveIndex: crate.sleeveIndex,
                        discArtwork: vm.crateDiscArtwork(for: index),
                        labelColor: crate.accentUIKit(),
                        rotation: spinning ? vm.cdAngle : 0,
                        cellSize: vinylCell
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { vm.crateVinylTapped(at: index) }
                }
            }
            .padding(.horizontal, c.outerPadding * s)
        }
        .frame(height: vinylCell)
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

struct FigmaCrateHeader: View {
    var scale: CGFloat = 1
    var onClose: () -> Void = {}

    private var c: FigmaTheme.Crate.Type { FigmaTheme.Crate.self }

    var body: some View {
        let s = scale
        let pad = c.headerPadding * s

        VStack(spacing: c.headerInnerGap * s) {
            ZStack {
                HStack(spacing: 0) {
                    Image(FigmaImage.cratesLogo)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: c.logoWidth * s, height: c.logoHeight * s, alignment: .leading)
                        .accessibilityLabel("Press")

                    Spacer(minLength: 0)

                    closeButton(scale: s)
                }

                Text("CRATES")
                    .font(FigmaFont.libraryTitle(c.titleFontSize * s))
                    .foregroundStyle(FigmaTheme.textDark)
            }

            Rectangle()
                .fill(FigmaTheme.textDark.opacity(0.75))
                .frame(height: c.dividerHeight * s)
        }
        .padding(pad)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func closeButton(scale s: CGFloat) -> some View {
        Button(action: onClose) {
            ZStack {
                Rectangle()
                    .stroke(
                        Color(red: 0.24, green: 0.24, blue: 0.24),
                        lineWidth: max(c.closeBorderWidth * s, FigmaTheme.snapToPixel(c.closeBorderWidth * s))
                    )
                    .frame(width: c.closeButtonSize * s, height: c.closeButtonSize * s)

                Image(FigmaImage.cratesClose)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 7.2 * s, height: 7.2 * s)
            }
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
