import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var vm = MusicPlayerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(OnboardingConfig.completionStorageKey) private var hasCompletedOnboarding = false

    private var showOnboarding: Bool {
        OnboardingConfig.isEnabled && !hasCompletedOnboarding
    }

    var body: some View {
        ZStack {
            if showOnboarding {
                FigmaOnboardingScreen {
                    hasCompletedOnboarding = true
                }
                .transition(.opacity)
            } else {
                Color.white.ignoresSafeArea(edges: .bottom)

                FigmaPlayerScreen(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !showOnboarding, vm.crateSavePhase != .idle {
                FigmaCrateDropSheet(vm: vm)
                    .zIndex(8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !showOnboarding, vm.showSettings {
                T3SettingsSheet(vm: vm)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }

            if !showOnboarding, vm.showLibrary {
                FigmaLibrarySheet(vm: vm)
                    .transition(.move(edge: .bottom))
                    .zIndex(11)
            }

            if !showOnboarding, vm.showSavedCrate {
                FigmaSavedCrateScreen(vm: vm)
                    .transition(.opacity)
                    .zIndex(12)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showSettings)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showLibrary)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showSavedCrate)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.crateSavePhase)
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                vm.pauseForBackground()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingDidReset)) { _ in
            hasCompletedOnboarding = false
        }
        .onAppear {
            VolumeManager.shared.attach(
                to: UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first
            )
        }
    }
}

#Preview {
    ContentView()
}
