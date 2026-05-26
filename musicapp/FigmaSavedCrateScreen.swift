import SwiftUI

// MARK: - Saved crate full screen (`396:3505` web · `401:3707` crates)

struct FigmaSavedCrateScreen: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @StateObject private var crateController = MilkCrateSceneController()
    @State private var sharePayload: SharePayload?
    @State private var isSharing = false
    @State private var shareProgress: Float = 0
    @State private var selectedMomentID: UUID?

    private var store: SavedCrateStore { vm.savedCrateStore }
    private var moments: [SavedMoment] { store.displayMoments }
    private var viewMode: SavedCrateViewMode { vm.savedCrateViewMode }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                creamHeader
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                shareFooter
            }

            if isSharing {
                Color.black.opacity(0.45).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView(value: shareProgress)
                        .tint(.white)
                        .frame(width: 200)
                    Text("Preparing share…")
                        .font(FigmaFont.mono(13))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            selectedMomentID = moments.first?.id
            crateController.updateSleeves(moments: moments)
        }
        .onChange(of: store.moments.count) { _, _ in
            if selectedMomentID == nil || !moments.contains(where: { $0.id == selectedMomentID }) {
                selectedMomentID = moments.first?.id
            }
            crateController.updateSleeves(moments: moments)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: shareItems(from: payload.images))
        }
    }

    // MARK: - Header (`399:3667`)

    private var creamHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                pressLogo
                    .frame(width: 48, height: 20, alignment: .leading)

                Spacer(minLength: 0)

                SavedCrateHybridTabSwitch(
                    mode: Binding(
                        get: { vm.savedCrateViewMode },
                        set: { vm.savedCrateViewMode = $0 }
                    )
                )

                Spacer(minLength: 0)

                closeButton
                    .frame(width: 48, height: 24, alignment: .trailing)
            }

            Rectangle()
                .fill(Color(red: 0.05, green: 0.05, blue: 0.04).opacity(0.75))
                .frame(height: 2)
        }
        .padding(16)
        .padding(.top, 16)
    }

    private var pressLogo: some View {
        Image(FigmaImage.cratesLogo)
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(height: 20)
            .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button {
            vm.closeSavedCrate()
        } label: {
            Image(FigmaImage.cratesClose)
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close saved crate")
        .accessibilityIdentifier("savedCrate.close")
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .web:
            SavedCrateWebView(
                moments: moments,
                selectedID: selectedMomentID,
                artworkFor: { vm.savedMomentDiscArtwork(for: $0) },
                onSelect: selectMoment
            )

        case .crate:
            SavedCrateTabView(
                vm: vm,
                controller: crateController,
                selectedMomentID: selectedMomentID,
                onSelect: selectMoment
            )
        }
    }

    // MARK: - Share footer (`401:3679`)

    private var shareFooter: some View {
        FigmaButtonHalf.midGrey(label: "SHARE", flex: false, scale: 117.333 / 176) {
            beginShare()
        }
        .frame(width: 117.333, height: 32)
        .disabled(moments.isEmpty)
        .opacity(moments.isEmpty ? 0.4 : 1)
        .padding(.bottom, 28)
        .accessibilityIdentifier("savedCrate.share")
    }

    // MARK: - Selection (stay open)

    private var selectedMoment: SavedMoment? {
        if let id = selectedMomentID, let m = moments.first(where: { $0.id == id }) {
            return m
        }
        if moments.indices.contains(crateController.frontIndex) {
            return moments[crateController.frontIndex]
        }
        return moments.first
    }

    private func selectMoment(_ moment: SavedMoment) {
        selectedMomentID = moment.id
        vm.impact(.light)
        vm.loadSavedMoment(moment)
    }

    // MARK: - Share

    private func beginShare() {
        guard let moment = selectedMoment else { return }
        isSharing = true
        shareProgress = 0

        if viewMode == .crate {
            crateController.setPopOut(1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let snapshot = viewMode == .web ? renderWebSnapshot() : nil
            let style: CrateShareImageGenerator.CrateShareStyle = viewMode == .web ? .floatingStack : .cratePopOut

            CrateShareImageGenerator.generate(
                moment: moment,
                allMoments: moments,
                style: style,
                cdAngle: vm.cdAngle,
                crateSnapshot: snapshot,
                progress: { shareProgress = $0 }
            ) { images in
                isSharing = false
                crateController.setPopOut(0)
                sharePayload = SharePayload(images: images)
            }
        }
    }

    @MainActor
    private func renderWebSnapshot() -> UIImage? {
        let layout = SavedCrateWebGraph.build(
            moments: moments,
            viewport: CGSize(width: 390, height: 560)
        )
        let view = ZStack(alignment: .topLeading) {
            SavedCrateDottedBackground(size: layout.canvasSize)
            SavedCrateWebVectorConnectors(
                nodes: layout.nodes,
                edges: layout.edges,
                canvasSize: layout.canvasSize
            )
            ForEach(layout.nodes) { node in
                SavedCrateWebDiscNode(
                    artwork: vm.savedMomentDiscArtwork(for: node.moment),
                    diameter: node.diameter,
                    isSelected: node.id == selectedMomentID
                )
                .position(node.center)
            }
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func shareItems(from images: ShareImages) -> [Any] {
        var items: [Any] = [images.instagramStory, images.instagramFeed, images.socialPortrait]
        if let mp4 = images.mp4URL { items.append(mp4) }
        return items
    }
}

// MARK: - Crates tab (`401:3707`)

private struct SavedCrateTabView: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @ObservedObject var controller: MilkCrateSceneController
    var selectedMomentID: UUID?
    let onSelect: (SavedMoment) -> Void

    private var store: SavedCrateStore { vm.savedCrateStore }
    private var moments: [SavedMoment] { store.displayMoments }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            if moments.isEmpty {
                emptyCrateIllustration
            } else {
                MilkCrateSceneView(controller: controller, allowsInteraction: true)
                    .frame(width: 300, height: 320)
                    .onTapGesture {
                        if let moment = frontMoment {
                            onSelect(moment)
                        }
                    }
            }

            Text(moments.isEmpty ? "save music to crate" : "fav music saved")
                .font(FigmaFont.libraryTitle(22))
                .foregroundStyle(Color(red: 0.05, green: 0.05, blue: 0.04))
                .padding(.top, moments.isEmpty ? 20 : 12)

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("savedCrate.crateTab")
    }

    private var emptyCrateIllustration: some View {
        MilkCrateSceneView(controller: controller, allowsInteraction: false)
            .frame(width: 300, height: 320)
            .opacity(0.92)
    }

    private var frontMoment: SavedMoment? {
        guard moments.indices.contains(controller.frontIndex) else {
            return moments.first
        }
        return moments[controller.frontIndex]
    }
}

extension ShareImages: Identifiable {
    var id: String { UUID().uuidString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SharePayload: Identifiable {
    let id = UUID()
    let images: ShareImages
}
