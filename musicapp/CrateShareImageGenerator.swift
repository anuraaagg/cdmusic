import UIKit
import AVFoundation

struct ShareImages {
    let base: UIImage
    let instagramStory: UIImage
    let instagramFeed: UIImage
    let socialPortrait: UIImage
    let mp4URL: URL?
}

enum CrateShareImageGenerator {
    static let rescale: CGFloat = 3

    static func generate(
        moment: SavedMoment,
        allMoments: [SavedMoment],
        style: CrateShareStyle,
        cdAngle: Double,
        crateSnapshot: UIImage?,
        progress: @escaping (Float) -> Void,
        completion: @escaping (ShareImages) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            progress(0.1)
            let canvasSize = CGSize(width: 390, height: 520)
            let base = renderCanvas(
                size: canvasSize,
                moment: moment,
                style: style,
                cdAngle: cdAngle,
                crateSnapshot: crateSnapshot
            )
            progress(0.45)

            let story = pad(base, aspect: 9 / 16, padTop: true)
            progress(0.6)
            let feed = pad(base, aspect: 1, padTop: false)
            progress(0.75)
            let portrait = pad(base, aspect: 3 / 4, padTop: false)
            progress(0.85)

            let mp4 = style == .cratePopOut
                ? encodeSimpleMP4(size: canvasSize, moment: moment, cdAngle: cdAngle, crateSnapshot: crateSnapshot)
                : nil
            progress(1)

            DispatchQueue.main.async {
                completion(ShareImages(
                    base: base,
                    instagramStory: story,
                    instagramFeed: feed,
                    socialPortrait: portrait,
                    mp4URL: mp4
                ))
            }
        }
    }

    enum CrateShareStyle { case cratePopOut, floatingStack }

    private static func renderCanvas(
        size: CGSize,
        moment: SavedMoment,
        style: CrateShareStyle,
        cdAngle: Double,
        crateSnapshot: UIImage?
    ) -> UIImage {
        let bg: UIColor = style == .floatingStack
            ? .black
            : UIColor(red: 244 / 255, green: 244 / 255, blue: 244 / 255, alpha: 1)

        let format = UIGraphicsImageRendererFormat()
        format.scale = rescale
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            bg.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            if style == .cratePopOut, let logo = UIImage(named: FigmaImage.cratesLogo) {
                logo.draw(in: CGRect(x: 20, y: 18, width: 72, height: 22))
            }

            if let art = moment.artworkImage {
                let discR: CGFloat = 88
                let discCenter = CGPoint(x: size.width / 2, y: 130)
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: discCenter.x, y: discCenter.y)
                ctx.cgContext.rotate(by: CGFloat(cdAngle) * .pi / 180)
                art.draw(in: CGRect(x: -discR, y: -discR, width: discR * 2, height: discR * 2))
                ctx.cgContext.restoreGState()
            }

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: style == .floatingStack ? UIColor.white : UIColor(red: 13/255, green: 12/255, blue: 10/255, alpha: 1)
            ]
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: style == .floatingStack ? UIColor.white.withAlphaComponent(0.65) : UIColor.black.withAlphaComponent(0.5)
            ]
            (moment.title as NSString).draw(at: CGPoint(x: 24, y: 230), withAttributes: titleAttrs)
            (moment.artist as NSString).draw(at: CGPoint(x: 24, y: 254), withAttributes: subAttrs)

            if let snap = crateSnapshot {
                snap.draw(in: CGRect(x: 40, y: 290, width: size.width - 80, height: 200))
            }

            let mark = "crates"
            (mark as NSString).draw(at: CGPoint(x: size.width - 56, y: size.height - 28), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.black.withAlphaComponent(0.25)
            ])
        }
    }

    private static func pad(_ base: UIImage, aspect: CGFloat, padTop: Bool) -> UIImage {
        let maxDim = max(base.size.width, base.size.height)
        let topPad = padTop ? ((base.size.width * (1 / aspect)) - base.size.height) / 2 : 0
        let size = CGSize(width: (maxDim + topPad) * aspect, height: maxDim + topPad)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let rect = CGRect(
                x: (size.width - base.size.width) / 2,
                y: topPad + (size.height - topPad - base.size.height) / 2,
                width: base.size.width,
                height: base.size.height
            )
            base.draw(in: rect)
        }
    }

    private static func encodeSimpleMP4(
        size: CGSize,
        moment: SavedMoment,
        cdAngle: Double,
        crateSnapshot: UIImage?
    ) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("crate_share_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: url)

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return nil }
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width * rescale),
            AVVideoHeightKey: Int(size.height * rescale)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(size.width * rescale),
                kCVPixelBufferHeightKey as String: Int(size.height * rescale)
            ]
        )
        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let frameCount = 45
        let fps: Int32 = 15
        for i in 0..<frameCount {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
            let angle = cdAngle + Double(i) * 8
            let pop = sin(Double(i) / Double(frameCount) * .pi) * 0.35
            let img = renderCanvas(size: size, moment: moment, style: .cratePopOut, cdAngle: angle, crateSnapshot: crateSnapshot)
            if let buffer = pixelBuffer(from: img, size: CGSize(width: size.width * rescale, height: size.height * rescale)) {
                let time = CMTime(value: CMTimeValue(i), timescale: fps)
                adaptor.append(buffer, withPresentationTime: time)
            }
            _ = pop
        }

        input.markAsFinished()
        let sem = DispatchSemaphore(value: 0)
        writer.finishWriting { sem.signal() }
        sem.wait()
        return writer.status == .completed ? url : nil
    }

    private static func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attrs, &buffer)
        guard let px = buffer else { return nil }
        CVPixelBufferLockBaseAddress(px, [])
        let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(px),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(px),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        ctx?.draw(image.cgImage!, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(px, [])
        return px
    }
}
