import UIKit

enum UIImageFigma {
    /// Flat disc tint for jewel-case mask filler when no streamed artwork.
    static func tintedDisc(_ color: UIColor, diameter: CGFloat = 512) -> UIImage {
        let s = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: s)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: s))

            ctx.cgContext.setBlendMode(.normal)
            let hole = CGFloat(diameter) * 0.12
            UIColor.darkGray.withAlphaComponent(0.12).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(
                x: (diameter - hole) / 2,
                y: (diameter - hole) / 2,
                width: hole,
                height: hole
            ))
        }
    }

    /// Figma sleeve template with library art composited into the label (Snoopy-style frame).
    static func compositeVinylSleeve(
        sleeveAssetName: String,
        artwork: UIImage?,
        labelColor: UIColor,
        diameter: CGFloat = 400
    ) -> UIImage {
        let s = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: s)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: s)
            let labelInset = diameter * 0.14
            let labelRect = rect.insetBy(dx: labelInset, dy: labelInset)

            if let sleeve = UIImage(named: sleeveAssetName) {
                sleeve.draw(in: rect)
            } else {
                labelColor.setFill()
                ctx.fill(rect)
            }

            if let art = artwork {
                ctx.cgContext.saveGState()
                ctx.cgContext.addEllipse(in: labelRect)
                ctx.cgContext.clip()
                art.draw(in: labelRect)
                ctx.cgContext.restoreGState()
            } else if UIImage(named: sleeveAssetName) == nil {
                labelColor.withAlphaComponent(0.35).setFill()
                ctx.cgContext.fillEllipse(in: labelRect)
            }
        }
    }
}
