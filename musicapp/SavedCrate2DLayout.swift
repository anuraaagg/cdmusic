import CoreGraphics

/// Layout for crate PNG + separate CD layer (no baked disc in the asset).
enum SavedCrate2DLayout {
    static let coordinateSpaceName = "savedCrate.2d"

    /// Cropped `saved_crate_green` asset (crate only, transparent/grey keyed).
    static let crateReferenceWidth: CGFloat = 600
    static let crateReferenceHeight: CGFloat = 580

    static let discDiameterRatio: CGFloat = 0.46
    /// Gap between crate bottom and disc center at rest.
    static let discBelowCrateRatio: CGFloat = 0.14

    /// Drop zone — interior opening of the crate (normalized to crate image).
    static let dropZoneMinX: CGFloat = 0.16
    static let dropZoneMaxX: CGFloat = 0.84
    static let dropZoneMinY: CGFloat = 0.18
    static let dropZoneMaxY: CGFloat = 0.52

    /// Landed disc center inside opening (normalized to crate image).
    static let discLandedYNormalized: CGFloat = 0.38

    struct Metrics {
        let crateWidth: CGFloat
        let crateHeight: CGFloat
        let totalHeight: CGFloat
        let discDiameter: CGFloat
        let discRestCenter: CGPoint
        let discLandedCenter: CGPoint
        let dropZone: CGRect
    }

    static func metrics(forCrateWidth width: CGFloat) -> Metrics {
        let crateHeight = width * (crateReferenceHeight / crateReferenceWidth)
        let discDiameter = width * discDiameterRatio
        let below = width * discBelowCrateRatio
        let totalHeight = crateHeight + below + discDiameter * 0.55

        let rest = CGPoint(
            x: width * 0.5,
            y: crateHeight + below + discDiameter * 0.5
        )
        let landed = CGPoint(
            x: width * 0.5,
            y: crateHeight * discLandedYNormalized
        )
        let zone = CGRect(
            x: width * dropZoneMinX,
            y: crateHeight * dropZoneMinY,
            width: width * (dropZoneMaxX - dropZoneMinX),
            height: crateHeight * (dropZoneMaxY - dropZoneMinY)
        )
        return Metrics(
            crateWidth: width,
            crateHeight: crateHeight,
            totalHeight: totalHeight,
            discDiameter: discDiameter,
            discRestCenter: rest,
            discLandedCenter: landed,
            dropZone: zone
        )
    }

    /// Back-compat alias used by older call sites.
    static func metrics(forWidth width: CGFloat) -> Metrics {
        metrics(forCrateWidth: width)
    }
}

extension SavedCrate2DLayout.Metrics {
    var forgivingDropZone: CGRect {
        dropZone.insetBy(dx: -24, dy: -40)
    }

    var flickAssistZone: CGRect {
        dropZone.insetBy(dx: -20, dy: -56)
    }

    func discCenter(offset: CGSize) -> CGPoint {
        CGPoint(
            x: discRestCenter.x + offset.width,
            y: discRestCenter.y + offset.height
        )
    }
}
