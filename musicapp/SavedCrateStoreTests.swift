import UIKit

#if DEBUG
enum SavedCrateStoreTests {
    @MainActor
    static func run() -> [String] {
        var failures: [String] = []
        let store = SavedCrateStore.shared
        store.resetForTesting()

        let moment = SavedMoment(
            trackPersistentID: 123,
            title: "TEST TRACK",
            artist: "TEST ARTIST",
            skin: .led,
            accentHex: 0xFF0000,
            artwork: UIImage(systemName: "music.note")
        )
        store.save(moment)
        if store.count != 1 { failures.append("save count expected 1 got \(store.count)") }
        if store.moments.first?.title != "TEST TRACK" { failures.append("title mismatch") }
        if store.moments.first?.artworkJPEG.isEmpty == true { failures.append("artwork empty") }

        store.delete(id: moment.id)
        if store.count != 0 { failures.append("delete failed") }

        return failures
    }
}
#endif
