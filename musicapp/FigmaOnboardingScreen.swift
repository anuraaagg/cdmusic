import SwiftUI
import UIKit

struct FigmaOnboardingScreen: View {
    var onComplete: () -> Void

    @State private var animate = false
    @State private var pageIdx = 0
    @State private var dragging = false
    @State private var pageTimer: Timer?

    private let buttonScale: CGFloat = 0.88

    private var headlineText: AttributedString {
        let markdown = [
            "**Flip-phone** playback\nfor your **local library.**",
            "Browse **vinyl & CDs**\nin the **crate carousel.**",
            "**Mechanical controls.**\n**Real haptics.**",
        ][pageIdx % 3]
        return (try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(markdown)
    }

    private var subtitleText: String {
        [
            "No streaming. No accounts.\nYour Music app, your crate.",
            "Swipe the panel. Pick a disc. Press play.",
            "Scratch the disc. Feel every key.",
        ][pageIdx % 3]
    }

    private var footerText: String {
        "No sign-up required unless you want to\nstore your library preferences."
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            FigmaOnboardingGradient(animate: $animate, pageIdx: $pageIdx)

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer(minLength: 8)
                copyBlock
                carouselBlock
                ctaBlock
                footerBlock
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            animate = true
            setupPageTimer()
        }
        .onDisappear { pageTimer?.invalidate() }
        .onChange(of: dragging) { _, isDragging in
            if isDragging {
                pageTimer?.invalidate()
            } else {
                setupPageTimer()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Image(FigmaImage.cratesLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 28)
            Spacer()
            FigmaButtonHalf.cream(label: "SKIP", flex: false, scale: buttonScale * 0.82) {
                complete()
            }
            .frame(width: FigmaButtonHalf.nativeWidth * buttonScale * 0.82)
        }
        .padding(.top, 8)
    }

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(headlineText)
                .font(.system(size: headlineSize, weight: .regular))
                .foregroundStyle(.white)
                .tracking(-0.5)
                .id("headline-\(pageIdx)")
                .transition(textTransition)

            Text(subtitleText)
                .font(FigmaFont.mono(14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .id("subtitle-\(pageIdx)")
                .transition(textTransition)
        }
    }

    private var carouselBlock: some View {
        FigmaOnboardingCarousel(pageIdx: $pageIdx, dragging: $dragging)
            .padding(.vertical, 16)
    }

    private var ctaBlock: some View {
        FigmaButtonHalf.orange(label: "GET STARTED", flex: true, scale: buttonScale) {
            complete()
        }
        .frame(maxWidth: .infinity)
        .frame(height: FigmaButtonHalf.nativeHeight * buttonScale)
    }

    private var footerBlock: some View {
        Text(footerText)
            .font(FigmaFont.mono(13))
            .foregroundStyle(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
    }

    private var headlineSize: CGFloat {
        (UIScreen.main.bounds.height * 0.041).clamped(to: 24...34)
    }

    private var textTransition: AnyTransition {
        .modifier(
            active: OnboardingBlurModifier(radius: 8),
            identity: OnboardingBlurModifier(radius: 0)
        )
        .combined(with: .opacity)
        .combined(with: .scale(scale: 0.9))
        .animation(OnboardingMotion.pageTransition)
    }

    private func complete() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        OnboardingConfig.markCompleted()
        onComplete()
    }

    private func setupPageTimer() {
        pageTimer?.invalidate()
        pageTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            pageIdx = (pageIdx + 1) % 3
        }
    }
}

private struct OnboardingBlurModifier: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

#Preview {
    FigmaOnboardingScreen(onComplete: {})
}
