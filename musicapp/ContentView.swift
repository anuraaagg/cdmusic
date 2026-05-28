import SwiftUI
import UIKit

struct ContentView: View {
    @State private var vm: MusicPlayerViewModel?
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(OnboardingConfig.completionStorageKey) private var hasCompletedOnboarding = false

    private var showOnboarding: Bool {
        OnboardingConfig.isEnabled && !hasCompletedOnboarding
    }

    var body: some View {
        ZStack {
            // Paint immediately — player mounts after bootstrap finishes.
            (showOnboarding ? Color.black : Color.white)
                .ignoresSafeArea()

            if let vm {
                playerStack(vm: vm)
            } else if !showOnboarding {
                ProgressView()
                    .tint(.gray.opacity(0.45))
            }

            if showOnboarding {
                FigmaOnboardingScreen {
                    finishOnboarding()
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .preferredColorScheme(.light)
        .task {
            await bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                vm?.pauseForBackground()
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

    @ViewBuilder
    private func playerStack(vm: MusicPlayerViewModel) -> some View {
        ZStack {
            FigmaPlayerScreen(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!showOnboarding)

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

            if !showOnboarding, vm.showArcadeGame {
                ArcadeGenreGameView(onClose: { vm.showArcadeGame = false })
                    .transition(.opacity)
                    .zIndex(13)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showSettings)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showLibrary)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showSavedCrate)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.showArcadeGame)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: vm.crateSavePhase)
    }

    @MainActor
    private func bootstrap() async {
        GoogleFontsRegistrar.registerBundledFonts()
        #if DEBUG
        LaunchSelfTests.runDeferred()
        #endif

        // Yield so SwiftUI can commit the splash/onboarding frame first.
        await Task.yield()

        if showOnboarding {
            // Warm the player while the user reads onboarding.
            let model = MusicPlayerViewModel()
            vm = model
        } else {
            vm = MusicPlayerViewModel()
            vm?.playerScreenDidAppear()
        }
    }

    @MainActor
    private func finishOnboarding() {
        hasCompletedOnboarding = true
        if vm == nil {
            vm = MusicPlayerViewModel()
        }
        vm?.playerScreenDidAppear()
    }
}

#Preview {
    ContentView()
}
