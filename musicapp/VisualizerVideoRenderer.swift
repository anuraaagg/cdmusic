import AVFoundation
import MetalKit
import QuartzCore
import simd

struct VisualizerVideoUniforms {
    var time: Float = 0
    var bass: Float = 0
    var mid: Float = 0
    var high: Float = 0
    var hue: Float = 0
    var grain: Float = 0
    var chroma: Float = 0
    var speed: Float = 1
    var satBoost: Float = 1.32
    var viewWidth: Float = 1
    var viewHeight: Float = 1
    var videoWidth: Float = 1
    var videoHeight: Float = 1
}

final class VisualizerVideoRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var textureCache: CVMetalTextureCache?
    private var uniformBuffer: MTLBuffer?

    private(set) var videoOutput: AVPlayerItemVideoOutput?
    private var lastTexture: MTLTexture?
    private var lastVideoWidth: Float = 1
    private var lastVideoHeight: Float = 1

    var uniforms = VisualizerVideoUniforms()

    override init() {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let queue = device.makeCommandQueue()
        else {
            fatalError("Metal is unavailable for visualizer video.")
        }
        self.device = device
        self.commandQueue = queue
        super.init()
        buildPipeline()
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<VisualizerVideoUniforms>.stride,
            options: .storageModeShared
        )
    }

    func attachVideoOutput(_ output: AVPlayerItemVideoOutput) {
        videoOutput = output
        output.requestNotificationOfMediaDataChange(withAdvanceInterval: 1.0 / 60.0)
    }

    func detachVideoOutput() {
        videoOutput = nil
        lastTexture = nil
    }

    func configure(view: MTKView) {
        view.device = device
        view.delegate = self
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.backgroundColor = .black
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.viewWidth = Float(max(size.width, 1))
        uniforms.viewHeight = Float(max(size.height, 1))
    }

    func draw(in view: MTKView) {
        guard
            let pipelineState,
            let drawable = view.currentDrawable,
            let passDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }

        if let output = videoOutput {
            let hostTime = CACurrentMediaTime()
            let itemTime = output.itemTime(forHostTime: hostTime)
            if output.hasNewPixelBuffer(forItemTime: itemTime),
               let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil),
               let texture = makeTexture(from: pixelBuffer) {
                lastTexture = texture
                lastVideoWidth = Float(CVPixelBufferGetWidth(pixelBuffer))
                lastVideoHeight = Float(CVPixelBufferGetHeight(pixelBuffer))
            }
        }

        guard let texture = lastTexture else {
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        uniforms.videoWidth = lastVideoWidth
        uniforms.videoHeight = lastVideoHeight
        if uniforms.viewWidth <= 1, view.drawableSize.width > 1 {
            uniforms.viewWidth = Float(view.drawableSize.width)
            uniforms.viewHeight = Float(view.drawableSize.height)
        }

        if let uniformBuffer {
            memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<VisualizerVideoUniforms>.stride)
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        if let uniformBuffer {
            encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        }
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else { return }

        let vertexFunction = library.makeFunction(name: "visualizerVideoVertex")
        let fragmentFunction = library.makeFunction(name: "visualizerVideoFragment")
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func makeTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTexture: CVMetalTexture?

        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )

        guard status == kCVReturnSuccess, let cvTexture else { return nil }
        return CVMetalTextureGetTexture(cvTexture)
    }
}
