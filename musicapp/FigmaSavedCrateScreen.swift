import SwiftUI

struct FigmaSavedCrateScreen: View {
    @ObservedObject var vm: MusicPlayerViewModel
    @StateObject private var crateController = MilkCrateSceneController()
    @State private var sharePayload: SharePayload?
    @State private var isSharing = false
    @State private var shareProgress: Float = 0
    @State private var shareStyle: CrateShareImageGenerator.CrateShareStyle = .cratePopOut

    private var store: SavedCrateStore { vm.savedCrateStore }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                crateView
                metaStrip
                Spacer(minLength: 12)
                hintBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if isSharing {
                Color.black.opacity(0.45).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView(value: shareProgress)
                        .tint(.white)
                        .frame(width: 200)
                    Text("Preparing share…")
                        .font(.custom("Helvetica", size: 13))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            crateController.updateSleeves(moments: store.moments)
        }
        .onChange(of: store.moments.count) { _, _ in
            crateController.updateSleeves(moments: store.moments)
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: shareItems(from: payload.images))
        }
    }

    private var header: some View {
        HStack {
            Button {
                vm.closeSavedCrate()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("savedCrate.close")

            Spacer()

            Text("My Crate")
                .font(FigmaFont.libraryTitle(18))
                .foregroundStyle(.white)

            Spacer()

            Button {
                beginShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(store.moments.isEmpty)
            .opacity(store.moments.isEmpty ? 0.35 : 1)
        }
    }

    private var crateView: some View {
        MilkCrateSceneView(controller: crateController, allowsInteraction: true)
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .onTapGesture {
                playFrontMoment()
            }
    }

    private var metaStrip: some View {
        let moment = frontMoment
        return VStack(spacing: 4) {
            Text(moment?.title.uppercased() ?? "EMPTY CRATE")
                .font(.custom("Helvetica", size: 14).weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(moment?.artist ?? "Long-press the CD to save a moment")
                .font(.custom("Helvetica", size: 12))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
        }
        .padding(.top, 16)
    }

    private var hintBar: some View {
        HStack {
            Text("← swipe →")
                .font(.custom("Helvetica", size: 11))
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
            Text("\(store.count) saved")
                .font(.custom("Helvetica", size: 11))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.bottom, 24)
    }

    private var frontMoment: SavedMoment? {
        guard store.moments.indices.contains(crateController.frontIndex) else {
            return store.moments.first
        }
        return store.moments[crateController.frontIndex]
    }

    private func playFrontMoment() {
        guard let moment = frontMoment else { return }
        vm.loadSavedMoment(moment)
        vm.closeSavedCrate()
    }

    private func beginShare() {
        guard let moment = frontMoment else { return }
        isSharing = true
        shareProgress = 0
        crateController.setPopOut(1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let snap: UIImage? = nil
            CrateShareImageGenerator.generate(
                moment: moment,
                allMoments: store.moments,
                style: shareStyle,
                cdAngle: vm.cdAngle,
                crateSnapshot: snap,
                progress: { shareProgress = $0 }
            ) { images in
                isSharing = false
                crateController.setPopOut(0)
                sharePayload = SharePayload(images: images)
            }
        }
    }

    private func shareItems(from images: ShareImages) -> [Any] {
        var items: [Any] = [images.instagramStory, images.instagramFeed]
        if let mp4 = images.mp4URL { items.append(mp4) }
        return items
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
