import Foundation
import UIKit

struct SavedMoment: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let trackPersistentID: UInt64?
    let title: String
    let artist: String
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
        skin: CDSkin,
        accentHex: UInt32?,
        artwork: UIImage?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.trackPersistentID = trackPersistentID
        self.title = title
        self.artist = artist
        self.skinRaw = skin.rawValue
        self.accentHex = accentHex
        self.artworkJPEG = Self.jpegData(from: artwork) ?? Self.placeholderJPEG()
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

enum CrateSavePhase: Equatable {
    case idle, lifting, morphing, dropReady, settling
}
