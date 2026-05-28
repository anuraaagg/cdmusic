import UIKit

#if DEBUG
enum SavedCrateStoreTests {
    /// Pure in-memory checks — does not touch `SavedCrateStore.shared` or disk.
    static func run() -> [String] {
        var failures: [String] = []

        let moment = SavedMoment(
            trackPersistentID: 123,
            title: "TEST TRACK",
            artist: "TEST ARTIST",
            genre: "SYNTH",
            skin: .led,
            accentHex: 0xFF0000,
            artwork: UIImage(systemName: "music.note")
        )

        guard let data = try? JSONEncoder().encode([moment]),
              let decoded = try? JSONDecoder().decode([SavedMoment].self, from: data) else {
            failures.append("codable roundtrip failed")
            return failures
        }

        if decoded.count != 1 { failures.append("save count expected 1 got \(decoded.count)") }
        if decoded.first?.title != "TEST TRACK" { failures.append("title mismatch") }
        if decoded.first?.artworkJPEG.isEmpty == true { failures.append("artwork empty") }

        return failures
    }
}
#endif
