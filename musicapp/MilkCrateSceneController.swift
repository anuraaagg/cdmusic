import RealityKit
import UIKit

@MainActor
final class MilkCrateSceneController: ObservableObject {
    let root = Entity()
    private let crateAnchor = Entity()
    private let sleeveAnchor = Entity()
    private var sleeveEntities: [ModelEntity] = []

    @Published var frontIndex = 0
    @Published var popOutProgress: CGFloat = 0
    @Published private(set) var crateLoaded = false
    @Published private(set) var usedProceduralCrate = false

    init() {
        root.addChild(crateAnchor)
        root.addChild(sleeveAnchor)
        loadCrate()
    }

    private func loadCrate() {
        guard let url = Bundle.main.url(forResource: "scene", withExtension: "gltf", subdirectory: "Resources/MilkCrate")
            ?? Bundle.main.url(forResource: "scene", withExtension: "gltf") else {
            addProceduralLatticeCrate()
            return
        }

        Task {
            do {
                let crate = try await Entity(contentsOf: url)
                await MainActor.run {
                    self.usedProceduralCrate = false
                    self.crateAnchor.children.removeAll()
                    crate.scale = SIMD3<Float>(repeating: 0.012)
                    crate.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                    crate.position = [0, -0.14, 0]
                    self.crateAnchor.addChild(crate)
                    self.crateLoaded = true
                }
            } catch {
                #if DEBUG
                print("[MilkCrateSceneController] glTF load failed (add scene.bin from Sketchfab or use procedural): \(error.localizedDescription)")
                #endif
                await MainActor.run {
                    self.addProceduralLatticeCrate()
                }
            }
        }
    }

    /// Green lattice milk crate (open slats — visible “holes”).
    func addProceduralLatticeCrate() {
        crateAnchor.children.removeAll()
        usedProceduralCrate = true

        let green = UIColor(red: 0.19, green: 0.55, blue: 0.31, alpha: 1)
        let darkInner = UIColor(red: 0.07, green: 0.09, blue: 0.08, alpha: 1)

        func plasticBox(
            _ size: SIMD3<Float>,
            _ position: SIMD3<Float>,
            color: UIColor,
            metallic: Float = 0.02,
            roughness: Float = 0.5
        ) -> ModelEntity {
            let radius = min(size.x, size.y, size.z) * 0.055
            let mesh = MeshResource.generateBox(size: size, cornerRadius: radius)
            var mat = SimpleMaterial()
            mat.color = .init(tint: color)
            mat.roughness = MaterialScalarParameter(floatLiteral: roughness)
            mat.metallic = MaterialScalarParameter(floatLiteral: metallic)
            let e = ModelEntity(mesh: mesh, materials: [mat])
            e.position = position
            return e
        }

        let outer: Float = 0.52
        let h: Float = 0.33
        let half = outer / 2
        let y0: Float = 0
        let slabT: Float = 0.018
        let post: Float = 0.036

        // Floor grid (minimal inner surface)
        crateAnchor.addChild(plasticBox(
            [outer - 0.06, 0.02, outer - 0.06],
            [0, -h / 2 + 0.012, 0],
            color: darkInner,
            roughness: 0.76
        ))

        func cornerPosts() {
            for sx in [-1, 1] as [Int] {
                for sz in [-1, 1] as [Int] {
                    let fx = Float(sx), fz = Float(sz)
                    crateAnchor.addChild(plasticBox(
                        [post, h, post],
                        [fx * (half - post / 2), y0, fz * (half - post / 2)],
                        color: green,
                        roughness: 0.52
                    ))
                }
            }
        }

        func verticalSlattedWall(alongZAxis: Bool) {
            let count = 7
            let span = outer - post * 2.35
            for i in 0..<count {
                let t = Float(i) / Float(max(count - 1, 1))
                let pu = -span / 2 + t * span
                if alongZAxis {
                    let zOuter = half - slabT * 0.55
                    for sign in [-1 as Float, 1] {
                        crateAnchor.addChild(plasticBox(
                            [slabT * 0.85, h * 0.86, slabT],
                            [pu, y0 + h * 0.02, sign * zOuter],
                            color: green,
                            roughness: 0.48
                        ))
                    }
                } else {
                    let xOuter = half - slabT * 0.55
                    for sign in [-1 as Float, 1] {
                        crateAnchor.addChild(plasticBox(
                            [slabT, h * 0.86, slabT * 0.85],
                            [sign * xOuter, y0 + h * 0.02, pu],
                            color: green,
                            roughness: 0.48
                        ))
                    }
                }
            }
        }

        cornerPosts()
        verticalSlattedWall(alongZAxis: true)
        verticalSlattedWall(alongZAxis: false)

        let lipH: Float = 0.024
        for sz in [-1 as Float, 1] {
            crateAnchor.addChild(plasticBox(
                [outer - 0.02, lipH, slabT * 1.1],
                [0, h / 2 - lipH / 2, sz * (half - slabT)],
                color: green,
                roughness: 0.4
            ))
        }

        crateLoaded = true
    }

    func updateSleeves(moments: [SavedMoment]) {
        Task {
            await rebuildSleeves(moments: moments)
        }
    }

    /// While the 2D disc animates toward the rim, show the stack **without** the moment that just saved.
    func showStackPriorToSaving(moments: [SavedMoment]) {
        guard moments.count >= 2 else {
            Task { await rebuildSleeves(moments: []) }
            return
        }
        Task {
            await rebuildSleeves(moments: Array(moments.dropFirst()))
            frontIndex = 0
        }
    }

    /// After cross-rim hand-off: animate the new sleeve from above into the front slot.
    func insertSavingMomentAtFront(_ moment: SavedMoment) {
        Task {
            let sleeve = await makeSleeve(moment: moment)
            sleeveAnchor.addChild(sleeve)
            sleeveEntities.insert(sleeve, at: 0)
            if sleeveEntities.count > 12, let tail = sleeveEntities.popLast() {
                tail.removeFromParent()
            }
            frontIndex = 0
            let landing = MilkCrateSleeveLayout.position(stackIndex: 0, frontIndex: frontIndex, count: sleeveEntities.count)
            let spawn = landing + SIMD3<Float>(0, MilkCrateSleeveLayout.insertSpawnYOffset(), 0.032)
            applyLayoutTransforms(animated: false, skipIndex: 0)
            sleeve.position = spawn
            orientStandingJacket(sleeve, stackIndex: 0)
            await animateLanding(entity: sleeve, end: landing + SIMD3<Float>(0, 0.13, 0), duration: CrateDropAnimationSpec.sleeveLandingDurationSeconds)
            layoutSleeves(animated: false)
            notifyChange()
        }
    }

    private func animateLanding(entity: ModelEntity, end: SIMD3<Float>, duration: TimeInterval) async {
        let start = entity.position
        let steps = max(14, Int(duration * 60))
        for frame in 0..<steps {
            let linear = Float(frame) / Float(max(steps - 1, 1))
            let t = 1 - (1 - linear) * (1 - linear)
            entity.position = simd_mix(start, end, SIMD3<Float>(repeating: t))
            try? await Task.sleep(nanoseconds: UInt64(duration * 1e9 / Double(steps)))
        }
        entity.position = end
    }

    private func rebuildSleeves(moments: [SavedMoment]) async {
        sleeveEntities.forEach { $0.removeFromParent() }
        sleeveEntities.removeAll()
        for moment in moments.prefix(12) {
            let sleeve = await makeSleeve(moment: moment)
            sleeveAnchor.addChild(sleeve)
            sleeveEntities.append(sleeve)
        }
        if frontIndex >= sleeveEntities.count { frontIndex = max(0, sleeveEntities.count - 1) }
        layoutSleeves(animated: false)
        notifyChange()
    }

    private func makeSleeve(moment: SavedMoment) async -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: 0.26, depth: 0.0026)
        var material = SimpleMaterial()
        if let image = artworkUIImage(for: moment),
           let cgImage = image.cgImage,
           let tex = try? await TextureResource(image: cgImage, withName: moment.id.uuidString, options: .init(semantic: .color)) {
            material.color = .init(tint: .white, texture: .init(tex))
        } else if let hex = moment.accentHex {
            material.color = .init(tint: UIColor.milkCrateAccent(hexRGB: hex))
        } else {
            material.color = .init(tint: UIColor(white: 0.42, alpha: 1))
        }
        material.roughness = 0.42
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = moment.id.uuidString
        return entity
    }

    private func artworkUIImage(for moment: SavedMoment) -> UIImage? {
        if let ui = moment.artworkImage { return ui }
        return UIImage(data: moment.artworkJPEG)
    }

    func layoutSleeves(animated: Bool) {
        applyLayoutTransforms(animated: animated, skipIndex: nil)
        notifyChange()
    }

    private func applyLayoutTransforms(animated: Bool, skipIndex: Int?) {
        let count = sleeveEntities.count
        for i in sleeveEntities.indices {
            if let skip = skipIndex, i == skip { continue }
            let sleeve = sleeveEntities[i]
            var pos = MilkCrateSleeveLayout.position(stackIndex: i, frontIndex: frontIndex, count: count)
            let d = MilkCrateSleeveLayout.normalizedDepth(stackIndex: i, frontIndex: frontIndex)
            pos.z += MilkCrateSleeveLayout.popOffsetZ(popOutProgress: i == frontIndex ? Float(popOutProgress) : 0)
            pos.y += 0.13
            orientStandingJacket(sleeve, stackIndex: i)
            let sc = CGFloat(MilkCrateSleeveLayout.sleeveScale(depthFromFrontHighlight: max(d, 0)))
            sleeve.scale = SIMD3<Float>(repeating: Float(sc))

            if animated {
                let end = pos
                let jitterDir: Float = (i % 2 == 0) ? 1 : -1
                let jitter = SIMD3<Float>(jitterDir * 0.0065, Float(i) * -0.0085, Float(i) * 0.012)
                let start = sleeve.position + jitter
                Task { @MainActor in
                    await tweenSleeve(entity: sleeve, from: start, to: end, duration: 0.24 + Double(i) * 0.04)
                }
            } else {
                sleeve.position = pos
            }
        }
    }

    private func orientStandingJacket(_ sleeve: ModelEntity, stackIndex _: Int) {
        let fi = frontIndex
        guard let idx = sleeveEntities.firstIndex(where: { $0 === sleeve }) else { return }
        let d = MilkCrateSleeveLayout.normalizedDepth(stackIndex: idx, frontIndex: fi)
        let yaw = MilkCrateSleeveLayout.yawHighlightPerDepth * d
        sleeve.orientation = simd_mul(
            simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]),
            simd_quatf(angle: yaw, axis: [0, 1, 0])
        )
    }

    private func tweenSleeve(entity: ModelEntity, from start: SIMD3<Float>, to end: SIMD3<Float>, duration: TimeInterval) async {
        let steps = max(14, Int(duration * 60))
        entity.position = start
        for frame in 0..<steps {
            let linear = Float(frame) / Float(max(steps - 1, 1))
            let t = 1 - (1 - linear) * (1 - linear)
            entity.position = simd_mix(start, end, SIMD3<Float>(repeating: t))
            try? await Task.sleep(nanoseconds: UInt64(duration * 1e9 / Double(steps)))
        }
        entity.position = end
    }

    func flipForward() {
        guard frontIndex < sleeveEntities.count - 1 else { return }
        frontIndex += 1
        layoutSleeves(animated: true)
    }

    func flipBackward() {
        guard frontIndex > 0 else { return }
        frontIndex -= 1
        layoutSleeves(animated: true)
    }

    func setPopOut(_ progress: CGFloat) {
        popOutProgress = max(0, min(1, progress))
        layoutSleeves(animated: false)
    }

    private func notifyChange() {
        objectWillChange.send()
    }
}

private extension UIColor {
    static func milkCrateAccent(hexRGB: UInt32, alpha: CGFloat = 1) -> UIColor {
        let r = CGFloat((hexRGB >> 16) & 0xFF) / 255
        let g = CGFloat((hexRGB >> 8) & 0xFF) / 255
        let b = CGFloat(hexRGB & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
}