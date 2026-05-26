import SwiftUI

// MARK: - InfiniteScroller

struct FigmaOnboardingInfiniteScroller<Content: View>: View {
    var contentWidth: CGFloat
    var reversed: Bool = true
    @ViewBuilder var content: () -> Content

    @State private var xOffset: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                content()
                content()
            }
            .offset(x: xOffset)
        }
        .disabled(true)
        .onAppear {
            if reversed {
                xOffset = -contentWidth
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                xOffset = reversed ? 0 : -contentWidth
            }
        }
    }
}

// MARK: - Feature chips (page 2)

struct FigmaOnboardingMarquee: View {
    private let chipSpacing: CGFloat = 8
    private let chipHeight: CGFloat = 32

    private let rows: [(labels: [String], reversed: Bool)] = [
        (["SCRATCH DISC", "JOG WHEEL", "HAPTICS", "UI SOUND", "DRAWER PHYSICS", "KEY PRESS"], true),
        (["LOCAL LIBRARY", "NO ACCOUNTS", "SHUFFLE", "REPEAT", "PREV", "NEXT"], false),
        (["SAVE TO CRATE", "LONG PRESS", "3D CRATE", "SHARE MOMENT", "VINYL RIPPLE"], true),
        (["CD CASE OPEN", "HERO ARTWORK", "DEMO CRATE", "CLEAR QUEUE", "VOLUME"], false),
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                chipRow(labels: row.labels, reversed: row.reversed)
                    .frame(height: chipHeight)
            }
        }
        .mask {
            LinearGradient(
                colors: [.clear, .black, .black, .black, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func chipRow(labels: [String], reversed: Bool) -> some View {
        let row = HStack(spacing: chipSpacing) {
            ForEach(labels, id: \.self) { label in
                chip(label)
            }
            Color.clear.frame(width: 0)
        }
        let width = CGFloat(labels.count) * 110 + CGFloat(labels.count) * chipSpacing
        return FigmaOnboardingInfiniteScroller(contentWidth: width, reversed: reversed) {
            row
        }
    }

    private func chip(_ label: String) -> some View {
        Text(label)
            .font(FigmaFont.mono(11, weight: .medium))
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.14), in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            }
    }
}
