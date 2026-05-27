import RealityKit
import UIKit

/// Loads the bundled milk-crate glTF only — CDs are drawn in SwiftUI (`SavedCrateFrontStackView`).
@MainActor
final class MilkCrateSceneController: ObservableObject {
    let root = Entity()
    private let crateAnchor = Entity()

    @Published private(set) var crateLoaded = false
    @Published private(set) var usedProceduralCrate = false

    init() {
        root.addChild(crateAnchor)
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
                print("[MilkCrateSceneController] glTF load failed: \(error.localizedDescription)")
                #endif
                await MainActor.run {
                    self.addProceduralLatticeCrate()
                }
            }
        }
    }

    /// Green lattice milk crate (open slats — visible “holes”) when glTF is missing.
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
}
