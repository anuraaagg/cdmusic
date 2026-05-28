import SwiftUI

/// Full-slot cosmic visualizer revealed when the control panel slides left.
struct CosmicVHSFullSlotView: View {
    @ObservedObject var vm: MusicPlayerViewModel

    @State private var time: Double = 0
    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            CosmicVHSTelevisionView(
                channel: vm.visualizerChannel,
                time: time,
                bass: vm.audioAnalyzer.bass,
                mid: vm.audioAnalyzer.mid,
                high: vm.audioAnalyzer.high,
                spinAngle: vm.cdAngle,
                speed: vm.visualizerSpeed,
                videoController: vm.visualizerVideoController
            )
        }
        .onReceive(tick) { _ in
            time += 1.0 / 60.0
        }
        .allowsHitTesting(false)
        .accessibilityIdentifier("visualizer.fullSlot")
    }
}
