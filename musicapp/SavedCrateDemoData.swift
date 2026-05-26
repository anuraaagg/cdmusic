import Foundation
import UIKit

#if DEBUG
/// Bundled vinyl moments for exercising the saved-crate web when nothing is saved yet.
enum SavedCrateDemoData {
    static let moments: [SavedMoment] = [
        moment(
            id: UUID(uuidString: "A1000001-0001-0001-0001-000000000001")!,
            title: "MIDNIGHT CASCADE",
            artist: "NEON DRIFT",
            genre: "ELECTRONIC",
            sleeveIndex: 0,
            skin: .normal,
            accentHex: 0x7144B0,
            dayOffset: 7
        ),
        moment(
            id: UUID(uuidString: "A1000002-0001-0001-0001-000000000002")!,
            title: "SOLAR FLARE",
            artist: "NEON DRIFT",
            genre: "SYNTH",
            sleeveIndex: 1,
            skin: .led,
            accentHex: 0xB83121,
            dayOffset: 6
        ),
        moment(
            id: UUID(uuidString: "A1000003-0001-0001-0001-000000000003")!,
            title: "SOLAR WINDS",
            artist: "PULSE ECHO",
            genre: "SYNTH",
            sleeveIndex: 1,
            skin: .led,
            accentHex: 0xB83121,
            dayOffset: 5
        ),
        moment(
            id: UUID(uuidString: "A1000004-0001-0001-0001-000000000004")!,
            title: "ECHO CHAMBER",
            artist: "PULSE ECHO",
            genre: "SYNTH",
            sleeveIndex: 2,
            skin: .crt,
            accentHex: 0x174EA8,
            dayOffset: 4
        ),
        moment(
            id: UUID(uuidString: "A1000005-0001-0001-0001-000000000005")!,
            title: "DEEP CURRENT",
            artist: "FLUX FIELD",
            genre: "AMB",
            sleeveIndex: 2,
            skin: .crt,
            accentHex: 0x174EA8,
            dayOffset: 3
        ),
        moment(
            id: UUID(uuidString: "A1000006-0001-0001-0001-000000000006")!,
            title: "DEEP BLUE",
            artist: "FLUX FIELD",
            genre: "AMB",
            sleeveIndex: 3,
            skin: .vinyl,
            accentHex: 0xB07010,
            dayOffset: 2
        ),
        moment(
            id: UUID(uuidString: "A1000007-0001-0001-0001-000000000007")!,
            title: "NEON RAIN",
            artist: "CIRCUIT",
            genre: "WAVE",
            sleeveIndex: 4,
            skin: .normal,
            accentHex: 0x0F8759,
            dayOffset: 1
        ),
        moment(
            id: UUID(uuidString: "A1000008-0001-0001-0001-000000000008")!,
            title: "PHASE SHIFT",
            artist: "ZERO ONE",
            genre: "TECHNO",
            sleeveIndex: 0,
            skin: .led,
            accentHex: 0xA11759,
            dayOffset: 0
        ),
    ]

    private static func moment(
        id: UUID,
        title: String,
        artist: String,
        genre: String,
        sleeveIndex: Int,
        skin: CDSkin,
        accentHex: UInt32,
        dayOffset: Int
    ) -> SavedMoment {
        let accent = UIColor(
            red: CGFloat((accentHex >> 16) & 0xFF) / 255,
            green: CGFloat((accentHex >> 8) & 0xFF) / 255,
            blue: CGFloat(accentHex & 0xFF) / 255,
            alpha: 1
        )
        let artwork = discArtwork(sleeveIndex: sleeveIndex, accent: accent)
        let savedAt = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        return SavedMoment(
            id: id,
            createdAt: savedAt,
            trackPersistentID: nil,
            title: title,
            artist: artist,
            genre: genre,
            skin: skin,
            accentHex: accentHex,
            artwork: artwork
        )
    }

    private static func discArtwork(sleeveIndex: Int, accent: UIColor) -> UIImage {
        if let sleeve = UIImage(named: FigmaImage.vinylSleeve(sleeveIndex)) {
            return sleeve
        }
        return UIImageFigma.tintedDisc(accent)
    }
}
#endif
