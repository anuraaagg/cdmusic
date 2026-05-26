import UIKit

// MARK: - Open IG / X instead of burying targets in the system share sheet (`401:3679`)

/// Best-effort: jump into Instagram Stories, Instagram proper, or the X/Twitter apps with artwork ready via pasteboard.
/// Falls back to `UIActivityViewController` when the app is missing or URLs are unsupported.
enum SocialDirectShare {

    enum Target {
        case instagramStory
        case instagramFeed
        case socialPortraitAndX /// 3∶4 portrait — routed to X (Twitter app)
    }

    @MainActor
    static func share(image: UIImage, target: Target) {
        let opened: Bool = {
            switch target {
            case .instagramStory:
                return openInstagramStory(with: image)
            case .instagramFeed:
                return openInstagramViaClipboard(with: image)
            case .socialPortraitAndX:
                return openXViaClipboard(with: image)
            }
        }()

        if !opened {
            UIActivitySharePresenter.present(activityItems: [image])
        }
    }

    // MARK: - Instagram Stories (`instagram-stories://`)

    /// Meta’s pasteboard contract for background image (see Instagram developer sharing docs).
    private static func openInstagramStory(with image: UIImage) -> Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        guard UIApplication.shared.canOpenURL(url) else { return false }
        guard let data = instagramStoriesBackgroundImageData(for: image) else { return false }

        let items: [[String: Any]] = [["com.instagram.sharedSticker.backgroundImage": data]]
        let options: [UIPasteboard.OptionsKey: Any] = [.expirationDate: Date().addingTimeInterval(120)]
        UIPasteboard.general.setItems(items, options: options)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }

    /// Compress if huge — Stories has practical limits on pasteboard payloads.
    private static func instagramStoriesBackgroundImageData(for image: UIImage) -> Data? {
        if let png = image.pngData(), png.count < 16_777_216 { return png }
        return image.jpegData(compressionQuality: 0.92)
    }

    // MARK: - Instagram (feed / composer)

    /// Clipboard image + foreground Instagram — Recent X/IG builds often prompt to use last clipboard photo in composer.
    private static func openInstagramViaClipboard(with image: UIImage) -> Bool {
        guard let ig = instagramAppURL(), UIApplication.shared.canOpenURL(ig) else { return false }
        UIPasteboard.general.items = []
        UIPasteboard.general.image = image
        UIApplication.shared.open(ig, options: [:], completionHandler: nil)
        return true
    }

    private static func instagramAppURL() -> URL? {
        URL(string: "instagram://app")
    }

    // MARK: - X (Twitter)

    /// Try known schemes in order (`twitter:` still resolves for many X installs).
    private static func openXViaClipboard(with image: UIImage) -> Bool {
        UIPasteboard.general.items = []
        UIPasteboard.general.image = image

        let candidates: [URL?] = [
            URL(string: "twitter://post"),
            URL(string: "twitter://compose"),
            URL(string: "x://timeline"),
            URL(string: "twitter://timeline"),
        ]
        for uc in candidates {
            guard let u = uc else { continue }
            if UIApplication.shared.canOpenURL(u) {
                UIApplication.shared.open(u, options: [:], completionHandler: nil)
                return true
            }
        }
        /// Last resort: bare `twitter://` often opens the installed client home / composer affordances.
        if let u = URL(string: "twitter://"), UIApplication.shared.canOpenURL(u) {
            UIApplication.shared.open(u, options: [:], completionHandler: nil)
            return true
        }
        return false
    }
}
