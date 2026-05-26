import SwiftUI

/// Animated blob backgrounds (three palettes cross-fade with `pageIdx`).
struct FigmaOnboardingGradient: View {
    @Binding var animate: Bool
    @Binding var pageIdx: Int

    private var warmColors: [Color] {
        ["#F98425", "#E82840", "#4A0D21", "#B12040", "#F4523B"].map(Color.init(onboardingHex:))
    }

    private var coolColors: [Color] {
        ["#B7F6FE", "#32A0FB", "#034EE7", "#0131A1", "#030C2F"].map(Color.init(onboardingHex:))
    }

    private var tealColors: [Color] {
        ["#66E7FF", "#04CFD5", "#00A077", "#00AF8B", "#02251B"].map(Color.init(onboardingHex:))
    }

    private func rand18(_ idx: Int) -> [Float] {
        let f = Float(idx)
        return [
            sin(f * 6.3),
            cos(f * 1.3 + 48),
            sin(f + 31.2),
            cos(f * 44.1),
            sin(f * 3333.2),
            cos(f + 1.12 * pow(f, 3)),
            sin(f * 22),
            cos(f * 34),
        ]
    }

    @ViewBuilder
    private func blobField(colors: [Color], seed: Int) -> some View {
        GeometryReader { geo in
            let maxX = Float(geo.size.width) / 2
            let maxY = Float(geo.size.height) / 2
            ZStack {
                ForEach(0..<10, id: \.self) { idx in
                    let r = rand18(idx + seed)
                    let fill = colors[idx % colors.count]
                    Ellipse()
                        .fill(fill)
                        .frame(
                            width: CGFloat(r[1] + 2) * 250,
                            height: CGFloat(r[2] + 2) * 250
                        )
                        .blur(radius: 45 * (1 + CGFloat(r[1] + r[2]) / 2))
                        .offset(
                            x: CGFloat(animate ? r[3] * maxX : r[4] * maxX),
                            y: CGFloat(animate ? r[5] * maxY : r[6] * maxY)
                        )
                        .animation(
                            .easeInOut(duration: TimeInterval(r[7] + 3) * 2.5)
                                .repeatForever(autoreverses: true),
                            value: animate
                        )
                }
            }
        }
    }

    var body: some View {
        ZStack {
            blobField(colors: warmColors, seed: 5)
                .opacity(pageIdx == 0 ? 1 : 0)
                .animation(OnboardingMotion.backgroundFade, value: pageIdx)

            blobField(colors: coolColors, seed: 5)
                .opacity(pageIdx == 1 ? 1 : 0)
                .animation(OnboardingMotion.backgroundFade, value: pageIdx)

            blobField(colors: tealColors, seed: 6)
                .opacity(pageIdx == 2 ? 1 : 0)
                .animation(OnboardingMotion.backgroundFade, value: pageIdx)
        }
        .drawingGroup()
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}
