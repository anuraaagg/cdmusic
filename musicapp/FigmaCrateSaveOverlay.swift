import SwiftUI

/// Full-screen white save flow — CD hold lifts the disc, crate morphs to fill the screen.
struct FigmaCrateSaveOverlay: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @StateObject private var crateController = MilkCrateSceneController()
    @State private var cdDragOffset: CGSize = .zero

    private var active: Bool { vm.crateSaveFromHero && vm.crateSavePhase != .idle }
    private var morph: CGFloat { vm.crateSaveMorphProgress }

    var body: some View {
        if active {
            GeometryReader { geo in
                let crateHeight = max(220, geo.size.height * (0.34 + morph * 0.22))
                let horizontalInset = max(0, 18 * (1 - morph))

                ZStack {
                    Color.white
                        .opacity(0.88 + morph * 0.12)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        floatingCD
                            .padding(.top, geo.safeAreaInsets.top + 20)

                        if vm.crateSavePhase == .dropReady {
                            Text("Drag down into the crate")
                                .font(.custom("Helvetica", size: 12))
                                .foregroundStyle(FigmaTheme.textDark.opacity(0.45))
                                .padding(.top, 10)
                                .transition(.opacity)
                        }

                        Spacer(minLength: 8)

                        cratePanel(height: crateHeight, horizontalInset: horizontalInset)

                        Spacer(minLength: max(geo.safeAreaInsets.bottom, 12))
                    }

                    Button {
                        vm.cancelCrateSave()
                        cdDragOffset = .zero
                    } label: {
                        Image(FigmaImage.cratesClose)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, geo.safeAreaInsets.top)
                    .padding(.trailing, 8)
                    .accessibilityLabel("Cancel save")
                }
            }
            .transition(.opacity)
            .onAppear {
                crateController.updateSleeves(moments: vm.savedCrateStore.moments)
            }
            .onChange(of: vm.crateSavePhase) { _, phase in
                if phase == .settling {
                    crateController.setPopOut(1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        crateController.setPopOut(0)
                    }
                }
            }
        }
    }

    private var floatingCD: some View {
        FigmaCDJewelCase(vm: vm, allowsInteraction: false)
            .frame(width: 280, height: 280)
            .scaleEffect(1 + morph * 0.08)
            .shadow(color: .black.opacity(0.12 + morph * 0.06), radius: 24 + morph * 12, y: 14)
            .offset(cdDragOffset)
            .gesture(cdDropGesture)
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: morph)
            .zIndex(2)
    }

    private func cratePanel(height: CGFloat, horizontalInset: CGFloat) -> some View {
        VStack(spacing: 14) {
            CratesLogoMorphView(
                morphProgress: morph,
                savedCount: vm.savedCrateStore.count,
                scale: vm.figmaLayoutScale
            )
            .padding(.horizontal, 28)

            MilkCrateSceneView(controller: crateController, allowsInteraction: morph > 0.7)
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 18 - morph * 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18 - morph * 6, style: .continuous)
                        .stroke(FigmaTheme.hairlineBorder.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28 - morph * 10, style: .continuous)
                .fill(FigmaTheme.crateInner)
                .shadow(color: .black.opacity(0.06 * morph), radius: 16, y: 6)
        )
        .padding(.horizontal, horizontalInset)
        .scaleEffect(x: 1, y: 0.86 + morph * 0.14, anchor: .bottom)
        .opacity(0.35 + morph * 0.65)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: morph)
    }

    private var cdDropGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard vm.crateSavePhase != .idle else { return }
                cdDragOffset = CGSize(width: value.translation.width * 0.35, height: max(0, value.translation.height))
            }
            .onEnded { value in
                let index = vm.crateSaveDragIndex ?? vm.crateActiveIndex
                if vm.crateSavePhase == .dropReady, value.translation.height > 48 {
                    vm.commitCrateSave(at: index)
                } else {
                    vm.cancelCrateSave()
                }
                cdDragOffset = .zero
            }
    }
}
