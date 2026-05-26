import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var vm = MusicPlayerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea(edges: .bottom)

            FigmaPlayerScreen(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if vm.crateSavePhase != .idle {
                FigmaCrateDropSheet(vm: vm)
                    .zIndex(8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if vm.showSettings {
                T3SettingsSheet(vm: vm)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }

            if vm.showLibrary {
                FigmaLibrarySheet(vm: vm)
                    .transition(.move(edge: .bottom))
                    .zIndex(11)
            }

            if vm.showSavedCrate {
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
