import SwiftUI

struct FigmaOnboardingCarousel: View {
    @Binding var pageIdx: Int
    @Binding var dragging: Bool

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat?

    private var cardSize: CGSize {
        let aspect: CGFloat = 2.052
        let verticalSafe = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?
            .safeAreaInsets ?? .zero
        let h = (UIScreen.main.bounds.height - verticalSafe.top - verticalSafe.bottom) * 0.435
        return CGSize(width: h / aspect, height: h)
    }

    private var secondPageOffset: CGFloat {
        cardSize.width * 3 + 16 * 3
    }

    private var thirdPageOffset: CGFloat {
        cardSize.width * 6 + 16 * 6
    }

    private var contentWidth: CGFloat {
        cardSize.width * 6 + UIScreen.main.bounds.width + 16 * 7
    }

    var body: some View {
        GeometryReader { geo in
            let screenW = geo.size.width > 0 ? geo.size.width : UIScreen.main.bounds.width
            HStack(spacing: 16) {
                ForEach(1...6, id: \.self) { screen in
                    card(for: screen, screenWidth: screenW)
                }
                FigmaOnboardingMarquee()
                    .frame(width: screenW)
            }
            .frame(height: cardSize.height)
            .offset(x: (contentWidth / 2) - (screenW / 2) - offset)
            .gesture(dragGesture(screenWidth: screenW))
            .onChange(of: pageIdx) { _, newValue in
                withAnimation(OnboardingMotion.pageTransition) {
                    switch newValue {
                    case 0: offset = 0
                    case 1: offset = secondPageOffset
                    default: offset = thirdPageOffset
                    }
                }
            }
        }
        .frame(height: cardSize.height)
    }

    private func card(for screen: Int, screenWidth: CGFloat) -> some View {
        GeometryReader { itemGeo in
            OnboardingCardPreviews.view(for: screen)
                .frame(width: cardSize.width, height: cardSize.height)
                .scaleEffect(parallaxScale(minX: itemGeo.frame(in: .global).minX, screenWidth: screenWidth))
                .offset(x: parallaxOffset(minX: itemGeo.frame(in: .global).minX, screenWidth: screenWidth))
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }

    private func parallaxScale(minX: CGFloat, screenWidth: CGFloat) -> CGFloat {
        (1 - (minX / screenWidth * 0.3)).clamped(to: 0...1)
    }

    private func parallaxOffset(minX: CGFloat, screenWidth: CGFloat) -> CGFloat {
        pow(minX / screenWidth, 2) * -60
    }

    private func dragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                if startOffset == nil { startOffset = offset }
                offset = startOffset! - (gesture.location.x - gesture.startLocation.x)
                dragging = true
            }
            .onEnded { gesture in
                let finalOffset = startOffset! - (gesture.predictedEndLocation.x - gesture.startLocation.x)
                let anchors = [0.0, secondPageOffset, thirdPageOffset]
                let closest = anchors.min(by: { abs($0 - finalOffset) < abs($1 - finalOffset) })!
                var closestPage = anchors.firstIndex(of: closest) ?? pageIdx
                closestPage = closestPage.clamped(to: (pageIdx - 1)...(pageIdx + 1))
                pageIdx = closestPage
                withAnimation(OnboardingMotion.carouselSnap) {
                    offset = anchors[closestPage]
                }
                startOffset = nil
                dragging = false
            }
    }
}
