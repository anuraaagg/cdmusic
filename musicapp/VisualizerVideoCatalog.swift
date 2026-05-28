import AVFoundation
import Foundation

enum VisualizerVideoCatalog {
    private static let clipNames = [
        "visualizer_01",
        "visualizer_02",
        "visualizer_03",
        "visualizer_04",
    ]

    static func randomURL() -> URL? {
        allURLs().randomElement()
    }

    static func allURLs() -> [URL] {
        var seen = Set<String>()
        var urls: [URL] = []

        func append(_ url: URL?) {
            guard let url else { return }
            let key = url.standardizedFileURL.path
            guard seen.insert(key).inserted else { return }
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            urls.append(url)
        }

        for name in clipNames {
            append(Bundle.main.url(forResource: name, withExtension: "mp4"))
            append(Bundle.main.url(
                forResource: name,
                withExtension: "mp4",
                subdirectory: "Resources/VisualizerVideos"
            ))
        }

        if let bundled = Bundle.main.urls(forResourcesWithExtension: "mp4", subdirectory: nil) {
            for url in bundled where url.lastPathComponent.hasPrefix("visualizer_") {
                append(url)
            }
        }

        if let resourceURL = Bundle.main.resourceURL,
           let enumerator = FileManager.default.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: nil
           ) {
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension.lowercased() == "mp4",
                      fileURL.lastPathComponent.hasPrefix("visualizer_") else { continue }
                append(fileURL)
            }
        }

        return urls
    }
}
