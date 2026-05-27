import SwiftUI
import RealityKit

struct MilkCrateSceneView: View {
    @ObservedObject var controller: MilkCrateSceneController
    var allowsInteraction: Bool = true

    var body: some View {
        RealityView { content in
            content.add(controller.root)

            var camera = PerspectiveCameraComponent()
            camera.fieldOfViewInDegrees = 36
            let cam = Entity()
            cam.components.set(camera)
            cam.position = [0, 0.42, 1.05]
            cam.look(at: [0, 0.085, -0.035], from: cam.position, relativeTo: nil)
            content.add(cam)

            let key = Entity()
            var dir = DirectionalLightComponent(color: .white, intensity: 5200)
            dir.isRealWorldProxy = false
            key.components.set(dir)
            key.look(at: [0, -0.12, 0], from: [1.4, 2.3, 1.25], relativeTo: nil)
            content.add(key)

            let rim = Entity()
            var fill = DirectionalLightComponent(color: .white, intensity: 980)
            fill.isRealWorldProxy = false
            rim.components.set(fill)
            rim.look(at: [0, 0.06, 0], from: [-1.6, 0.85, 1.1], relativeTo: nil)
            content.add(rim)
        }
        .allowsHitTesting(allowsInteraction)
    }
}
