import SwiftUI

struct AlbumEntry: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let accent: Color
    let skin: CDSkin
}

enum AlbumCatalog {
    static let entries: [AlbumEntry] = [
        AlbumEntry(title: "Midnight Cascade", artist: "Neon Drift",  accent: Color(red: 0.44, green: 0.19, blue: 0.69), skin: .normal),
        AlbumEntry(title: "Solar Winds",      artist: "Pulse Echo",  accent: Color(red: 0.72, green: 0.19, blue: 0.13), skin: .led),
        AlbumEntry(title: "Deep Current",     artist: "Flux Field",  accent: Color(red: 0.09, green: 0.31, blue: 0.66), skin: .crt),
        AlbumEntry(title: "Amber Static",     artist: "The Groove",  accent: Color(red: 0.69, green: 0.44, blue: 0.06), skin: .vinyl),
        AlbumEntry(title: "Neon Rain",        artist: "Circuit",     accent: Color(red: 0.06, green: 0.53, blue: 0.35), skin: .normal),
        AlbumEntry(title: "Phase Shift",      artist: "Zero One",    accent: Color(red: 0.63, green: 0.09, blue: 0.35), skin: .led),
        AlbumEntry(title: "Static Dreams",    artist: "Analog Soul", accent: Color(red: 0.16, green: 0.41, blue: 0.60), skin: .crt),
        AlbumEntry(title: "Warm Machine",     artist: "Low Hum",     accent: Color(red: 0.56, green: 0.28, blue: 0.13), skin: .vinyl),
        AlbumEntry(title: "Night Circuit",    artist: "Sub Layer",   accent: Color(red: 0.22, green: 0.28, blue: 0.60), skin: .normal),
    ]
}
