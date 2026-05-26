import Foundation
import Combine

@MainActor
final class SavedCrateStore: ObservableObject {
    static let shared = SavedCrateStore()

    @Published private(set) var moments: [SavedMoment] = []

    private let maxCount = 50
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("saved_crate_moments.json")
        load()
    }

    var count: Int { moments.count }

    /// Saved moments shown in the crate UI — real saves, or DEBUG demo vinyls when empty.
    var displayMoments: [SavedMoment] {
        #if DEBUG
        if !moments.isEmpty { return moments }
        guard !ProcessInfo.processInfo.arguments.contains("-NoSavedCrateDemo") else { return [] }
        return SavedCrateDemoData.moments
        #else
        return moments
        #endif
    }

    var displayCount: Int { displayMoments.count }

    var isShowingDemoData: Bool {
        #if DEBUG
        moments.isEmpty && !displayMoments.isEmpty
        #else
        false
        #endif
    }

    @discardableResult
    func save(_ moment: SavedMoment) -> Bool {
        if moments.count >= maxCount { moments.removeLast() }
        moments.insert(moment, at: 0)
        persist()
        return true
    }

    func delete(id: UUID) {
        moments.removeAll { $0.id == id }
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([SavedMoment].self, from: data) else { return }
        moments = decoded
    }

    #if DEBUG
    func resetForTesting() {
        moments = []
        try? FileManager.default.removeItem(at: fileURL)
    }
    #endif

    private func persist() {
        guard let data = try? encoder.encode(moments) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
