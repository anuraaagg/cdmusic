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

    init() {
        root.addChild(crateAnchor)
        root.addChild(sleeveAnchor)
        loadCrate()
    }

    private func loadCrate() {
        guard let url = Bundle.main.url(forResource: "scene", withExtension: "gltf", subdirectory: "Resources/MilkCrate")
            ?? Bundle.main.url(forResource: "scene", withExtension: "gltf") else { return }

        Task {
            do {
                let crate = try await Entity(contentsOf: url)
                crate.scale = SIMD3(repeating: 0.012)
                crate.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                crate.position = [0, -0.15, 0]
                crateAnchor.addChild(crate)
                crateLoaded = true
            } catch {
                addFallbackCrate()
            }
        }
    }

    private func addFallbackCrate() {
        let mesh = MeshResource.generateBox(size: [0.55, 0.38, 0.55], cornerRadius: 0.02)
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(red: 0.18, green: 0.35, blue: 0.22, alpha: 1))
        material.roughness = 0.65
        let box = ModelEntity(mesh: mesh, materials: [material])
        crateAnchor.addChild(box)
        crateLoaded = true
    }

    func updateSleeves(moments: [SavedMoment]) {
        Task {
            await rebuildSleeves(moments: moments)
        }
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
    }

    private func makeSleeve(moment: SavedMoment) async -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: 0.28, depth: 0.28)
        var material = SimpleMaterial()
        if let image = moment.artworkImage,
           let cgImage = image.cgImage,
           let tex = try? await TextureResource(image: cgImage, withName: moment.id.uuidString, options: .init(semantic: .color)) {
            material.color = .init(tint: .white, texture: .init(tex))
        } else {
            material.color = .init(tint: .darkGray)
        }
        material.roughness = 0.4
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = moment.id.uuidString
        return entity
    }

    func layoutSleeves(animated: Bool) {
        for (i, entity) in sleeveEntities.enumerated() {
            let depth = Float(i - frontIndex)
            let x = depth * 0.18
            let z = -abs(depth) * 0.05
            let pop = (i == frontIndex) ? Float(popOutProgress) * 0.22 : 0
            entity.position = [x, 0.12 + pop, z + pop * 0.2]
            entity.orientation = simd_quatf(angle: depth * 0.08, axis: [0, 1, 0])
            let s: Float = (i == frontIndex) ? 1.06 + pop * 0.08 : 0.9
            entity.scale = [s, s, s]
        }
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
}
