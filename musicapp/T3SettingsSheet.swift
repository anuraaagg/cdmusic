import SwiftUI

struct T3SettingsSheet: View {
    @ObservedObject var vm: MusicPlayerViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: T3Layout.sectionGap) {
                Capsule()
                    .fill(T3Color.bgDarkGrey)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)

                HStack(spacing: 16) {
                    T3ButtonHybrid(label: "SOUND", isOn: vm.isSoundEnabled) {
                        vm.isSoundEnabled.toggle()
                        vm.impact(.light)
                    }
                    T3ButtonHybrid(label: "HAPTIC", isOn: vm.isHapticEnabled) {
                        vm.isHapticEnabled.toggle()
                        vm.impact(.light)
                    }
                }
                .padding(.horizontal, T3Layout.screenInset)

                HStack {
                    Spacer()
                    T3Button(label: "CLEAR QUEUE", style: .blackNum) {
                        vm.clearQueue()
                        dismiss()
                    }
                    Spacer()
                }

                HStack {
                    Spacer()
                    T3Button(label: "GENRE ARCADE", style: .blackNum) {
                        vm.showSettings = false
                        vm.showArcadeGame = true
                        vm.impact(.medium)
                    }
                    Spacer()
                }

                #if DEBUG
                HStack {
                    Spacer()
                    T3Button(label: "RESET ONBOARDING", style: .blackNum) {
                        OnboardingConfig.resetCompletion()
                        dismiss()
                    }
                    Spacer()
                }
                #endif

                Text("MusicPlayer 1.0 · Terms · Privacy")
                    .font(T3Font.labelDetail())
                    .foregroundColor(T3Color.bgDarkGrey.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, T3Layout.screenInset)

                HStack {
                    T3ButtonSymbol(kind: .return, action: dismiss)
                    Spacer()
                }
                .padding(.horizontal, T3Layout.screenInset)
                .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(T3Color.surfacePrimary)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .ignoresSafeArea()
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            vm.showSettings = false
        }
    }
}

#Preview {
    T3SettingsSheet(vm: MusicPlayerViewModel())
}
