import Foundation
import UIKit

struct SavedMoment: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let trackPersistentID: UInt64?
    let title: String
    let artist: String
    let genre: String
    let skinRaw: String
    let accentHex: UInt32?
    let artworkJPEG: Data

    var skin: CDSkin { CDSkin(rawValue: skinRaw) ?? .normal }
    var artworkImage: UIImage? { UIImage(data: artworkJPEG) }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        trackPersistentID: UInt64?,
        title: String,
        artist: String,
        genre: String = "",
        skin: CDSkin,
        accentHex: UInt32?,
        artwork: UIImage?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.trackPersistentID = trackPersistentID
        self.title = title
        self.artist = artist
        self.genre = genre
        self.skinRaw = skin.rawValue
        self.accentHex = accentHex
        self.artworkJPEG = Self.jpegData(from: artwork) ?? Self.placeholderJPEG()
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        trackPersistentID = try c.decodeIfPresent(UInt64.self, forKey: .trackPersistentID)
        title = try c.decode(String.self, forKey: .title)
        artist = try c.decode(String.self, forKey: .artist)
        genre = try c.decodeIfPresent(String.self, forKey: .genre) ?? ""
        skinRaw = try c.decode(String.self, forKey: .skinRaw)
        accentHex = try c.decodeIfPresent(UInt32.self, forKey: .accentHex)
        artworkJPEG = try c.decode(Data.self, forKey: .artworkJPEG)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(trackPersistentID, forKey: .trackPersistentID)
        try c.encode(title, forKey: .title)
        try c.encode(artist, forKey: .artist)
        try c.encode(genre, forKey: .genre)
        try c.encode(skinRaw, forKey: .skinRaw)
        try c.encodeIfPresent(accentHex, forKey: .accentHex)
        try c.encode(artworkJPEG, forKey: .artworkJPEG)
    }

    private enum CodingKeys: String, CodingKey {
        case id, createdAt, trackPersistentID, title, artist, genre, skinRaw, accentHex, artworkJPEG
    }

    private static func jpegData(from image: UIImage?, maxSide: CGFloat = 512, quality: CGFloat = 0.82) -> Data? {
        guard let image else { return nil }
        let side = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(side, 1))
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: quality)
    }

    private static func placeholderJPEG() -> Data {
        let size = CGSize(width: 256, height: 256)
        let img = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(white: 0.15, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return img.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

enum SavedCrateViewMode: String, CaseIterable, Identifiable, Hashable {
    case web
    case crate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .web: return "Web"
        case .crate: return "Crate"
        }
    }
}

/// Unified crate-drop bottom sheet (`FigmaCrateDropSheet`).
enum CrateSavePhase: Equatable {
    case idle
    /// Sheet shown at peek; expanding to drop detent.
    case presenting
    /// Sheet expanded; user can drag or flick vinyl into the opening.
    case expanded
    /// Save committed; vinyl animates into the crate.
    case settling
    /// Saved; sleeves updated — user dismisses explicitly (✕ / scrim).
    case success
}
