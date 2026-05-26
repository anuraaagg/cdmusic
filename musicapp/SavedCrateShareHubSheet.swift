import SwiftUI
import UIKit

/// Carries paired export packs so the picker can swipe between layouts before sending to IG / X.
struct SavedCrateShareHubPayload: Identifiable {
    let id = UUID()
    let webImages: ShareImages
    let crateImages: ShareImages
}

// MARK: - Activity presentation (Stories / X from SwiftUI sheets)

enum UIActivitySharePresenter {
    @MainActor
    static func present(activityItems: [Any]) {
        let filtered = activityItems.filter { !($0 is NSNull) }
        guard !filtered.isEmpty else { return }

        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = scene.windows.first(where: { $0.isKeyWindow }),
            let root = window.rootViewController
        else { return }

        let presenter = presenterChain(from: root)
        let av = UIActivityViewController(activityItems: filtered, applicationActivities: nil)
        av.popoverPresentationController?.sourceView = window
        av.popoverPresentationController?.sourceRect = CGRect(
            x: window.bounds.midX,
            y: window.bounds.midY,
            width: 1,
            height: 1
        )
        av.popoverPresentationController?.permittedArrowDirections = []
        presenter.present(av, animated: true)
    }

    private static func presenterChain(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return presenterChain(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return presenterChain(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return presenterChain(from: selected)
        }
        return vc
    }
}

// MARK: - Hub UI (`396:3505`)

struct SavedCrateShareHubSheet: View {
    let payload: SavedCrateShareHubPayload

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private var active: ShareImages { page == 0 ? payload.webImages : payload.crateImages }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                TabView(selection: $page) {
                    previewCard(
                        title: "Web grid",
                        caption: "Strands · dots · draggable layout",
                        image: payload.webImages.base
                    )
                    .tag(0)

                    previewCard(
                        title: "Crate shelf",
                        caption: "3D crate peek",
                        image: payload.crateImages.base
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 360)

                VStack(spacing: 10) {
                    shareChromeButton(
                        title: "Instagram Story · 9∶16",
                        accessibilityId: "savedCrate.share.story"
                    ) {
                        SocialDirectShare.share(image: active.instagramStory, target: .instagramStory)
                    }

                    shareChromeButton(
                        title: "Instagram · square feed",
                        accessibilityId: "savedCrate.share.feed"
                    ) {
                        SocialDirectShare.share(image: active.instagramFeed, target: .instagramFeed)
                    }

                    shareChromeButton(
                        title: "X · portrait (3∶4)",
                        accessibilityId: "savedCrate.share.x"
                    ) {
                        SocialDirectShare.share(image: active.socialPortrait, target: .socialPortraitAndX)
                    }

                    if let mp4 = active.mp4URL {
                        shareChromeButton(
                            title: "Share crate clip (video)",
                            accessibilityId: "savedCrate.share.video"
                        ) {
                            UIActivitySharePresenter.present(activityItems: [mp4])
                        }
                    }

                    Button {
                        var items: [Any] = [active.instagramStory, active.instagramFeed, active.socialPortrait]
                        if let v = active.mp4URL { items.append(v) }
                        UIActivitySharePresenter.present(activityItems: items)
                    } label: {
                        Text("More sharing options…")
                            .font(FigmaFont.mono(13))
                            .foregroundStyle(Color(white: 0.42))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .accessibilityIdentifier("savedCrate.share.more")
                }
                .padding(.horizontal, 4)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .navigationTitle("Share collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("savedCrate.share.dismiss")
                }
            }
            .background(SavedCrateCanvasChrome.fieldFill.ignoresSafeArea())
        }
    }

    private func previewCard(title: String, caption: String, image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(FigmaFont.libraryTitle(20))
                .foregroundStyle(Color(red: 0.05, green: 0.05, blue: 0.04))
            Text(caption)
                .font(FigmaFont.mono(12))
                .foregroundStyle(Color(white: 0.45))

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                .padding(.vertical, 4)

            swipeHint()
        }
    }

    private func swipeHint() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(white: 0.52))
            Text("Swipe to compare layouts")
                .font(FigmaFont.mono(11))
                .foregroundStyle(Color(white: 0.52))
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func shareChromeButton(title: String, accessibilityId: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FigmaFont.mono(14))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.46, green: 0.45, blue: 0.46),
                            Color(red: 0.28, green: 0.27, blue: 0.28),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
        .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
    }
}
