import SwiftUI
import UIKit

/// Palette derived from album artwork for the jewel-case gyro shine.
struct JewelCaseShinePalette: Equatable {
    let gradientHues: [Double]
    let gradientStops: [Gradient.Stop]
    let accentHue: Double
    let usesFullSpectrumField: Bool
    let fieldSpanLower: Double
    let fieldSpanUpper: Double

    static let rainbow = JewelCaseShinePalette(
        gradientHues: [0.00, 0.10, 0.18, 0.33, 0.52, 0.66, 0.78, 0.92],
        accentHue: 0.58,
        usesFullSpectrumField: true,
        fieldSpanLower: 0,
        fieldSpanUpper: 1
    )

    init(
        gradientHues: [Double],
        accentHue: Double,
        usesFullSpectrumField: Bool,
        fieldSpanLower: Double,
        fieldSpanUpper: Double
    ) {
        self.gradientHues = gradientHues
        self.accentHue = accentHue
        self.usesFullSpectrumField = usesFullSpectrumField
        self.fieldSpanLower = fieldSpanLower
        self.fieldSpanUpper = fieldSpanUpper
        self.gradientStops = Self.makeGradientStops(from: gradientHues)
    }

    func hue(forNormalizedDistance t: Double) -> Double {
        let clamped = min(1, max(0, t))
        if usesFullSpectrumField { return clamped }
        return (fieldSpanLower + (fieldSpanUpper - fieldSpanLower) * clamped)
            .truncatingRemainder(dividingBy: 1)
    }

    static func fromAccentHex(_ hex: UInt32) -> JewelCaseShinePalette {
        if let cached = accentCache[hex] { return cached }
        let palette = makeFromAccentHex(hex)
        accentCache[hex] = palette
        return palette
    }

    private static var accentCache: [UInt32: JewelCaseShinePalette] = [:]

    private static func makeFromAccentHex(_ hex: UInt32) -> JewelCaseShinePalette {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        let (hue, _, _) = rgbToHSB(r: r, g: g, b: b)
        return fromDominantHue(hue)
    }

    // MARK: - Extraction (background-safe)

    static func extract(from image: UIImage) -> JewelCaseShinePalette? {
        let side = 32
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let thumb = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }

        guard
            let cgImage = thumb.cgImage,
            let data = cgImage.dataProvider?.data,
            let bytes = CFDataGetBytePtr(data)
        else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 3 else { return nil }

        let bucketCount = 24
        var bucketWeight = [Double](repeating: 0, count: bucketCount)
        var bucketHueSum = [Double](repeating: 0, count: bucketCount)
        var sampled = 0
        let stride = 2

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                let r = Double(bytes[offset]) / 255
                let g = Double(bytes[offset + 1]) / 255
                let b = Double(bytes[offset + 2]) / 255

                let (hue, saturation, brightness) = rgbToHSB(r: r, g: g, b: b)
                if saturation >= 0.12, brightness >= 0.14, brightness <= 0.98 {
                    sampled += 1
                    let weight = saturation * brightness
                    let bucket = min(bucketCount - 1, Int(hue * Double(bucketCount)))
                    bucketWeight[bucket] += weight
                    bucketHueSum[bucket] += hue * weight
                }
                x += stride
            }
            y += stride
        }

        guard sampled >= 12 else { return nil }

        let ranked = bucketWeight.enumerated().sorted { $0.element > $1.element }
        var hues: [Double] = []
        hues.reserveCapacity(6)
        let minSeparation = 0.07

        for (index, weight) in ranked where weight > 0 {
            let hue = bucketHueSum[index] / weight
            let separated = hues.allSatisfy { existing in
                circularHueDistance(existing, hue) >= minSeparation
            }
            guard separated else { continue }
            hues.append(hue)
            if hues.count >= 6 { break }
        }

        guard !hues.isEmpty else { return nil }
        hues.sort()

        if hues.count == 1 {
            return fromDominantHue(hues[0])
        }

        let gradientHues = interpolateHues(hues, count: 8)
        let first = hues[0]
        let last = hues[hues.count - 1]
        let padding = max(0.04, circularHueDistance(first, last) * 0.12)

        return JewelCaseShinePalette(
            gradientHues: gradientHues,
            accentHue: hues[hues.count / 2],
            usesFullSpectrumField: false,
            fieldSpanLower: first - padding,
            fieldSpanUpper: last + padding
        )
    }

    static func fingerprint(of image: UIImage) -> UInt64 {
        let side = 16
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let thumb = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }

        guard
            let cgImage = thumb.cgImage,
            let data = cgImage.dataProvider?.data,
            let bytes = CFDataGetBytePtr(data)
        else { return 0 }

        var hash: UInt64 = 1469598103934665603
        let length = CFDataGetLength(data)
        for i in 0..<length {
            hash ^= UInt64(bytes[i])
            hash &*= 1099511628211
        }
        return hash
    }

    // MARK: - Private helpers

    private static func fromDominantHue(_ center: Double) -> JewelCaseShinePalette {
        let gradientHues = (0..<8).map { i in
            (center + Double(i) / 8 * 0.22 - 0.11).truncatingRemainder(dividingBy: 1)
        }
        return JewelCaseShinePalette(
            gradientHues: gradientHues,
            accentHue: center,
            usesFullSpectrumField: false,
            fieldSpanLower: center - 0.12,
            fieldSpanUpper: center + 0.12
        )
    }

    private static func makeGradientStops(from hues: [Double]) -> [Gradient.Stop] {
        hues.enumerated().map { index, hue in
            Gradient.Stop(
                color: Color(hue: hue, saturation: 0.88, brightness: 1),
                location: Double(index) / Double(max(1, hues.count - 1))
            )
        }
    }

    private static func interpolateHues(_ hues: [Double], count: Int) -> [Double] {
        guard count > 1, !hues.isEmpty else { return hues }
        if hues.count == 1 { return Array(repeating: hues[0], count: count) }

        return (0..<count).map { index in
            let t = Double(index) / Double(count - 1)
            let scaled = t * Double(hues.count - 1)
            let lower = Int(floor(scaled))
            let upper = min(hues.count - 1, lower + 1)
            let fraction = scaled - Double(lower)
            return lerpHue(hues[lower], hues[upper], fraction)
        }
    }

    private static func rgbToHSB(r: Double, g: Double, b: Double) -> (h: Double, s: Double, br: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        let brightness = maxC
        guard delta > 0.0001 else { return (0, 0, brightness) }

        let saturation = delta / maxC
        let hue: Double
        if maxC == r {
            hue = ((g - b) / delta + (g < b ? 6 : 0)) / 6
        } else if maxC == g {
            hue = ((b - r) / delta + 2) / 6
        } else {
            hue = ((r - g) / delta + 4) / 6
        }
        return (hue, saturation, brightness)
    }

    private static func circularHueDistance(_ a: Double, _ b: Double) -> Double {
        let delta = abs(a - b)
        return min(delta, 1 - delta)
    }

    private static func lerpHue(_ a: Double, _ b: Double, _ t: Double) -> Double {
        var delta = b - a
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        return (a + delta * t).truncatingRemainder(dividingBy: 1)
    }
}

// MARK: - Cached async resolver

actor JewelCaseShinePaletteResolver {
    static let shared = JewelCaseShinePaletteResolver()

    private var cache: [UInt64: JewelCaseShinePalette] = [:]
    private var cacheOrder: [UInt64] = []
    private let maxEntries = 48

    func cachedPalette(for key: UInt64) -> JewelCaseShinePalette? {
        cache[key]
    }

    func palette(for key: UInt64, image: UIImage) async -> JewelCaseShinePalette {
        if let cached = cache[key] { return cached }

        let extracted = await Task.detached(priority: .utility) {
            JewelCaseShinePalette.extract(from: image) ?? JewelCaseShinePalette.rainbow
        }.value

        store(key: key, palette: extracted)
        return extracted
    }

    func palette(forAccentHex hex: UInt32) -> JewelCaseShinePalette {
        JewelCaseShinePalette.fromAccentHex(hex)
    }

    private func store(key: UInt64, palette: JewelCaseShinePalette) {
        if cache[key] != nil {
            cacheOrder.removeAll { $0 == key }
        }
        cache[key] = palette
        cacheOrder.append(key)
        while cacheOrder.count > maxEntries {
            let evicted = cacheOrder.removeFirst()
            cache.removeValue(forKey: evicted)
        }
    }
}
