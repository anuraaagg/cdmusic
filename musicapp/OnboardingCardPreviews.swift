import SwiftUI

/// Illustrated looping previews for onboarding carousel cards.
enum OnboardingCardPreviews {
    static func view(for screen: Int) -> some View {
        OnboardingCardChrome {
            Group {
                switch screen {
                case 1: PlayerIllustration()
                case 2: CaseOpenIllustration()
                case 3: LibraryIllustration()
                case 4: DrawerIllustration()
                case 5: VinylCarouselIllustration()
                case 6: PressPlayIllustration()
                default: EmptyView()
                }
            }
        }
    }
}

// MARK: - Drawing helpers

private enum OnboardingDraw {
    static let ink = Color.white.opacity(0.92)
    static let inkDim = Color.white.opacity(0.45)
    static let accent = Color(red: 0.95, green: 0.29, blue: 0.05)

    static func strokeStyle(_ w: CGFloat = 2.2) -> StrokeStyle {
        StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
    }

    static func wobble(_ t: Double, amp: CGFloat = 3) -> CGFloat {
        CGFloat(sin(t * 4.7)) * amp
    }
}

// MARK: - S1 — flip player + CD hero

private struct PlayerIllustration: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Image(FigmaImage.cdCoverArt)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(OnboardingDraw.ink, lineWidth: 2))
                    .rotationEffect(.degrees(t * 40))
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(OnboardingDraw.inkDim, lineWidth: 1.5)
                        .frame(width: 100, height: 118)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(OnboardingDraw.ink.opacity(0.12))
                        .frame(width: 88, height: 20)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(OnboardingDraw.inkDim, lineWidth: 1)
                        }
                }
            }
        }
    }
}

// MARK: - S2 — jewel case opens

private struct CaseOpenIllustration: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let phase = sin(timeline.date.timeIntervalSinceReferenceDate * 1.2)
            let slide = CGFloat((phase + 1) / 2) * 22
            ZStack {
                Image(FigmaImage.cdCaseTray)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .offset(x: -slide)
                    .opacity(0.95)
                Image(FigmaImage.cdDisc)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .offset(x: 18 + slide * 0.4)
                    .rotationEffect(.degrees(Double(phase) * 12))
            }
            Canvas { ctx, size in
                var arrow = Path()
                let ax = size.width * 0.22 + slide
                arrow.move(to: CGPoint(x: ax, y: size.height * 0.72))
                arrow.addLine(to: CGPoint(x: ax - 18, y: size.height * 0.72))
                arrow.addLine(to: CGPoint(x: ax - 10, y: size.height * 0.72 - 8))
                ctx.stroke(arrow, with: .color(OnboardingDraw.accent), style: OnboardingDraw.strokeStyle(2))
            }
        }
    }
}

// MARK: - S3 — library sheet

private struct LibraryIllustration: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let lift = (sin(timeline.date.timeIntervalSinceReferenceDate * 1.1) + 1) / 2
            let sheetH: CGFloat = 44 + CGFloat(lift) * 56
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 8) {
                    Text("LIBRARY")
                        .font(FigmaFont.libraryTitle(11))
                        .foregroundStyle(OnboardingDraw.ink)
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(OnboardingDraw.ink.opacity(0.12 + Double(i) * 0.04))
                            .frame(height: 8)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(height: sheetH)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(OnboardingDraw.inkDim, lineWidth: 1)
                }
            }
            .overlay(alignment: .topTrailing) {
                Image(FigmaImage.dialA2)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .padding(8)
                    .opacity(0.9)
            }
        }
    }
}

// MARK: - S4 — drawer / crate

private struct DrawerIllustration: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let reveal = (sin(timeline.date.timeIntervalSinceReferenceDate * 1.3) + 1) / 2
            let revealOffset = CGFloat(reveal) * 32
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 28)
                    .overlay {
                        Capsule()
                            .fill(OnboardingDraw.inkDim)
                            .frame(width: 36, height: 4)
                    }
                VStack(spacing: 8) {
                    Text("CRATES")
                        .font(FigmaFont.status(10))
                        .foregroundStyle(OnboardingDraw.ink)
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(FigmaImage.vinylSleeve(i))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(OnboardingDraw.inkDim, lineWidth: 1))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(FigmaTheme.crateInner.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            }
            .offset(y: -revealOffset)
            .overlay(alignment: .top) {
                Canvas { ctx, size in
                    var finger = Path()
                    finger.move(to: CGPoint(x: size.width / 2, y: 4))
                    finger.addQuadCurve(
                        to: CGPoint(x: size.width / 2 + OnboardingDraw.wobble(reveal * 10), y: 22 + revealOffset * 0.2),
                        control: CGPoint(x: size.width / 2 + 14, y: 10)
                    )
                    ctx.stroke(finger, with: .color(OnboardingDraw.accent), style: OnboardingDraw.strokeStyle(2))
                }
                .frame(height: 36)
            }
        }
    }
}

// MARK: - S5 — vinyl pick

private struct VinylCarouselIllustration: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let drift = CGFloat(sin(t * 1.5)) * 18
            HStack(spacing: 14) {
                ForEach(0..<3, id: \.self) { i in
                    let scale: CGFloat = i == 1 ? 1 : 0.82
                    let op: Double = i == 1 ? 1 : 0.55
                    Image(FigmaImage.vinylSleeve(i + 1))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52 * scale, height: 52 * scale)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(OnboardingDraw.ink, lineWidth: i == 1 ? 2 : 1)
                        }
                        .shadow(color: i == 1 ? OnboardingDraw.accent.opacity(0.4) : .clear, radius: 8)
                        .opacity(op)
                }
            }
            .offset(x: drift)
            .overlay {
                Canvas { ctx, size in
                    var hand = Path()
                    hand.addEllipse(in: CGRect(x: size.width / 2 - 8, y: size.height - 20, width: 16, height: 10))
                    ctx.fill(hand, with: .color(OnboardingDraw.accent.opacity(0.7)))
                }
            }
        }
    }
}

// MARK: - S6 — press play

private struct PressPlayIllustration: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let pulse = (sin(timeline.date.timeIntervalSinceReferenceDate * 2.2) + 1) / 2
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("PLAYING")
                        .font(FigmaFont.status(9))
                        .foregroundStyle(FigmaTheme.textDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(FigmaTheme.jamPillFill, in: Capsule())
                    Text("03/12")
                        .font(FigmaFont.counter(9))
                        .foregroundStyle(FigmaTheme.jamCounterText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(FigmaTheme.jamPillFill.opacity(0.85), in: Capsule())
                }
                Image(FigmaImage.vinylSleeve(2))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(OnboardingDraw.ink, lineWidth: 2))
                    .scaleEffect(1 + CGFloat(pulse) * 0.04)
                HStack(spacing: 6) {
                    FigmaSquareButton.play(scale: 0.42) {}
                        .allowsHitTesting(false)
                    FigmaSquareButton.pause(scale: 0.42) {}
                        .allowsHitTesting(false)
                        .opacity(0.35 + pulse * 0.65)
                }
            }
        }
    }
}
