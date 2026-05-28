import SwiftUI

// MARK: - FigmaCDHeroView
//
// Top section — Figma `305:3028` + CD jewel case `305:2722` / slide-open `360:2854`.

struct FigmaCDHeroView: View {
    @ObservedObject var vm: MusicPlayerViewModel
    var spacing: FigmaResponsiveSpacing = .init(tightness: 1, scale: 1, tier: .large)

    var body: some View {
        VStack(spacing: FigmaTheme.heroMetaGap) {
            FigmaCDJewelCase(vm: vm)
                .frame(width: FigmaTheme.heroCDSize, height: FigmaTheme.heroCDSize)

            FigmaHeroMetaStrip(
                songTitle: vm.heroTrackTitle,
                timeText: vm.heroTimeString,
                genre: vm.heroGenre,
                onAsteriskTap: {
                    vm.impact(.light)
                    vm.showLibrary = false
                    vm.showSettings = true
                }
            )
            .animation(nil, value: vm.caseSlideFraction)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - FigmaCDJewelCase

struct FigmaCDJewelCase: View {
    @ObservedObject var vm: MusicPlayerViewModel
    var allowsInteraction: Bool = true

    @StateObject private var caseShineMotion = JewelCaseMotionShineModel()
    @State private var caseDragAnchor: CGFloat = 0
    @State private var isCaseDragging = false
    /// Live fraction while dragging — avoids publishing to the VM each frame (prevents gesture / disc conflicts).
    @State private var dragSlideFraction: CGFloat?

    @State private var discDragStartAngle: Double?
    @State private var discLastAngle: Double?
    @State private var seekAnchor = 0.0
    @State private var isDiscDragging = false

    private static let side = FigmaTheme.heroCDSize
    private static let cd = FigmaTheme.CD3052722.self

    private var slideFraction: CGFloat { dragSlideFraction ?? vm.caseSlideFraction }

    private var discOffsetX: CGFloat {
        Self.cd.discClosedOffsetX + Self.cd.discSlideDistance * slideFraction
    }

    private var discOffsetY: CGFloat { Self.cd.discClosedOffsetY }

    private var caseOffsetX: CGFloat { -Self.cd.caseSlideDistance * slideFraction }

    /// Leading band that still shows case plastic — tray drag only (not the exposed disc).
    private var shellHitWidth: CGFloat {
        if !allowsInteraction { return Self.side }
        if isCaseDragging { return Self.side }
        return max(0, Self.side - Self.cd.caseSlideDistance * slideFraction)
    }

    private var discInteractionEnabled: Bool {
        allowsInteraction && slideFraction >= Self.cd.discInteractThreshold && !isCaseDragging
    }

    private var discCenter: CGPoint {
        CGPoint(
            x: discOffsetX + Self.cd.discWidth / 2,
            y: discOffsetY + Self.cd.discHeight / 2
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            discLayer
                .position(discCenter)
                .frame(width: Self.side, height: Self.side)

            caseLayer
                .offset(x: caseOffsetX)

            if allowsInteraction {
                if discInteractionEnabled {
                    discInteractionTarget
                }
                shellDragTarget
            }
        }
        .frame(width: Self.side, height: Self.side, alignment: .topLeading)
        .clipped()
        .animation(nil, value: slideFraction)
        .onAppear {
            caseShineMotion.configure(size: CGSize(width: Self.side, height: Self.side))
            caseShineMotion.start()
        }
        .onDisappear { caseShineMotion.stop() }
    }

    private var cdHoldGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .onEnded { _ in
                guard vm.crateSavePhase == .idle else { return }
                vm.beginCrateDrop(at: vm.crateActiveIndex, fromHero: true)
            }
    }

    // MARK: - Layers

    private var discLayer: some View {
        let w = Self.cd.discWidth
        let h = Self.cd.discHeight

        return ZStack {
            discArtworkFill
                .frame(width: w, height: h)
                .clipped()
                .mask(
                    Image(FigmaImage.cdDisc)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: w, height: h)
                )
                .rotationEffect(.degrees(vm.cdAngle), anchor: .center)
                .animation(nil, value: vm.cdAngle)

            if slideFraction >= Self.cd.discInteractThreshold {
                Circle()
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    /// Spin / scrub / tap — full disc hit target; shell band above wins on the left edge.
    private var discInteractionTarget: some View {
        let w = Self.cd.discWidth
        let h = Self.cd.discHeight

        return Color.clear
            .frame(width: w, height: h)
            .contentShape(Circle())
            .highPriorityGesture(discSpinGesture)
            .simultaneousGesture(discTapGestures)
            .simultaneousGesture(cdHoldGesture)
            .position(discCenter)
            .frame(width: Self.side, height: Self.side)
    }

    /// Case close/open — shell plastic band only (leading edge).
    private var shellDragTarget: some View {
        Color.clear
            .frame(width: shellHitWidth, height: Self.side, alignment: .leading)
            .contentShape(
                JewelCaseHitRegion(
                    externalDragTarget: !allowsInteraction,
                    slideFraction: slideFraction,
                    caseSlideDistance: Self.cd.caseSlideDistance,
                    expanded: isCaseDragging
                )
            )
            .gesture(trayDragGesture)
            .simultaneousGesture(cdHoldGesture)
    }

    @ViewBuilder
    private var discArtworkFill: some View {
        if let ui = vm.heroDiscArtwork {
            Image(uiImage: ui).resizable().scaledToFill()
        } else if let placeholder = vm.heroDiscPlaceholder {
            Image(uiImage: placeholder).resizable().scaledToFill()
        } else {
            Image(FigmaImage.cdDisc).resizable().scaledToFill()
        }
    }

    private var caseTrayMask: some View {
        Image(FigmaImage.cdCaseTray)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: Self.side, height: Self.side)
    }

    private var caseLayer: some View {
        ZStack(alignment: .topLeading) {
            Image(FigmaImage.cdCaseTray)
                .resizable()
                .scaledToFit()
                .frame(width: Self.side, height: Self.side)
                .allowsHitTesting(false)

            JewelCaseGyroShineOverlay(
                focalPoint: caseShineMotion.focalPoint,
                size: Self.side,
                tiltAmount: caseShineMotion.tiltAmount,
                palette: vm.heroCaseShinePalette
            )
                .mask { caseTrayMask }
                .allowsHitTesting(false)

            Image(FigmaImage.cdCaseSpine)
                .resizable()
                .scaledToFit()
                .frame(width: Self.cd.spineWidth, height: Self.cd.spineHeight)
                .offset(x: Self.cd.spineOffsetX, y: Self.cd.spineOffsetY)
                .allowsHitTesting(false)
        }
        .frame(width: Self.side, height: Self.side)
        .allowsHitTesting(false)
    }

    // MARK: - Tray drag (case hit region only — disc keeps scrub)

    private var trayDragGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                let horiz = abs(value.translation.width)
                let vert = abs(value.translation.height)
                guard horiz > vert * 0.38 || isCaseDragging else { return }

                if !isCaseDragging {
                    isCaseDragging = true
                    caseDragAnchor = slideFraction
                    vm.impact(.soft)
                }

                dragSlideFraction = CaseTrayPhysics.dragFraction(
                    anchor: caseDragAnchor,
                    horizontalTranslation: value.translation.width,
                    slideDistance: Self.cd.caseSlideDistance
                )
            }
            .onEnded { _ in
                guard isCaseDragging else { return }
                isCaseDragging = false
                finishTrayDrag()
            }
    }

    private func finishTrayDrag() {
        let current = dragSlideFraction ?? vm.caseSlideFraction
        dragSlideFraction = nil
        let target = CaseTrayPhysics.snapTarget(fraction: current)
        vm.selectionChanged()
        withAnimation(CaseTrayPhysics.snapAnimation) {
            vm.caseSlideFraction = target
        }
    }

    // MARK: - Disc scrub / spin (open only, isolated from tray)

    private var discSpinGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let discCenterX = Self.cd.discWidth / 2
                let discCenterY = Self.cd.discHeight / 2
                let angle = Self.degrees(atan2(
                    value.location.y - discCenterY,
                    value.location.x - discCenterX
                ))

                if !isDiscDragging {
                    isDiscDragging = true
                    discDragStartAngle = angle
                    discLastAngle = angle
                    seekAnchor = vm.progress
                    vm.impact(.rigid)
                }

                if let prev = discLastAngle {
                    let delta = Self.wrap(angle - prev)
                    vm.scratch(delta: delta, velocity: delta * 0.85)
                    vm.seek(to: min(1, max(0, seekAnchor + (angle - (discDragStartAngle ?? angle)) / 360.0)))
                }
                discLastAngle = angle
            }
            .onEnded { _ in
                isDiscDragging = false
                discDragStartAngle = nil
                discLastAngle = nil
                vm.endScratch()
                vm.impact(.light)
            }
    }

    private var discTapGestures: some Gesture {
        ExclusiveGesture(
            TapGesture(count: 2).onEnded {
                vm.seek(bySeconds: 30)
                vm.impact(.medium)
            },
            TapGesture(count: 1).onEnded {
                vm.togglePlay()
            }
        )
    }

    private static func degrees(_ radians: CGFloat) -> Double { Double(radians) * 180 / .pi }

    private static func wrap(_ d: Double) -> Double {
        var x = d
        if x > 180 { x -= 360 }
        if x < -180 { x += 360 }
        return x
    }
}

// MARK: - Case hit region

/// In-app tray uses the sliding band so the thumb stays on shell plastic; crate sheet hero copy uses full rect so drops work even when tray is slid open (`slideFraction > 0`).
private struct JewelCaseHitRegion: Shape {
    /// `true` = crate-sheet copy (`allowsInteraction == false`): whole jewel frame is draggable.
    var externalDragTarget: Bool
    var slideFraction: CGFloat
    var caseSlideDistance: CGFloat
    var expanded: Bool

    func path(in rect: CGRect) -> Path {
        if externalDragTarget {
            return Path(rect)
        }
        var p = Path()
        if expanded {
            p.addRect(rect)
            return p
        }
        // Case slides left as `slideFraction` increases — keep hits on the visible shell (leading band).
        let shellWidth = max(0, rect.width - caseSlideDistance * slideFraction)
        guard shellWidth > 0 else { return p }
        p.addRect(CGRect(x: 0, y: 0, width: shellWidth, height: rect.height))
        return p
    }
}

// MARK: - Top-half geometry

enum FigmaTopHalf {
    static let heroSafeAreaTop: CGFloat = 48
    static let maxTopInset: CGFloat = 8
    static var contentStackHeight: CGFloat {
        let stripH = max(FigmaTheme.heroMetaStripH, FigmaTheme.minTouchTarget)
        return FigmaTheme.heroCDSize + FigmaTheme.heroMetaGap + stripH
    }
    static let nativeWidth: CGFloat = 402
    static let topInset: CGFloat = heroSafeAreaTop + maxTopInset
    static let contentHeight: CGFloat = topInset + contentStackHeight
}

#Preview("CD Hero — closed") {
    FigmaCDHeroView(vm: MusicPlayerViewModel())
        .frame(width: 402, height: FigmaTopHalf.contentHeight)
        .background(Color.white)
}

#Preview("CD Hero — tray open") {
    let vm = MusicPlayerViewModel()
    vm.caseSlideFraction = 1
    return FigmaCDHeroView(vm: vm)
        .frame(width: 402, height: FigmaTopHalf.contentHeight)
        .background(Color.white)
}
