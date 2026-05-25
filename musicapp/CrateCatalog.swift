import SwiftUI
import UIKit

/// Demo crate rows wired to bundled vinyl sleeves (Figma carousel).
struct CrateCatalogEntry: Identifiable, Hashable {
    let id: Int
    let title: String
    let artist: String
    let genrePlaceholder: String
    let sleeveIndex: Int
    let skin: CDSkin
    let accentHex: UInt32

    var accentColorSwiftUI: Color {
        let r = CGFloat((accentHex >> 16) & 0xFF) / CGFloat(255)
        let g = CGFloat((accentHex >> 8) & 0xFF) / CGFloat(255)
        let b = CGFloat(accentHex & 0xFF) / CGFloat(255)
        return Color(red: r, green: g, blue: b)
    }

    func accentUIKit() -> UIColor {
        UIColor(
            red: CGFloat((accentHex >> 16) & 0xFF) / 255,
            green: CGFloat((accentHex >> 8) & 0xFF) / 255,
            blue: CGFloat(accentHex & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum CrateCatalog {
    static let entries: [CrateCatalogEntry] = [
        CrateCatalogEntry(id: 0, title: "MIDNIGHT CASCADE", artist: "NEON DRIFT", genrePlaceholder: "ELECTRONIC", sleeveIndex: 0, skin: .normal, accentHex: 0x7144B0),
        CrateCatalogEntry(id: 1, title: "SOLAR WINDS", artist: "PULSE ECHO", genrePlaceholder: "SYNTH", sleeveIndex: 1, skin: .led, accentHex: 0xB83121),
        CrateCatalogEntry(id: 2, title: "DEEP CURRENT", artist: "FLUX FIELD", genrePlaceholder: "AMB", sleeveIndex: 2, skin: .crt, accentHex: 0x174EA8),
        CrateCatalogEntry(id: 3, title: "AMBER STATIC", artist: "THE GROOVE", genrePlaceholder: "FUNK", sleeveIndex: 3, skin: .vinyl, accentHex: 0xB07010),
        CrateCatalogEntry(id: 4, title: "NEON RAIN", artist: "CIRCUIT", genrePlaceholder: "WAVE", sleeveIndex: 4, skin: .normal, accentHex: 0x0F8759),
    ]

    static var count: Int { entries.count }

    static func sleeveForIndex(_ i: Int) -> Int {
        entries[i % entries.count].sleeveIndex
    }
}
