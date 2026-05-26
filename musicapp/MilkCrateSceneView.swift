import SwiftUI
import RealityKit

struct MilkCrateSceneView: View {
    @ObservedObject var controller: MilkCrateSceneController
    var allowsInteraction: Bool = true

    var body: some View {
        RealityView { content in
            content.add(controller.root)

            var camera = PerspectiveCameraComponent()
            camera.fieldOfViewInDegrees = 42
            let cam = Entity()
            cam.components.set(camera)
            cam.position = [0, 0.55, 1.35]
            cam.look(at: [0, 0.05, 0], from: cam.position, relativeTo: nil)
            content.add(cam)
        }
        .gesture(
            allowsInteraction ?
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -30 { controller.flipForward() }
                    else if value.translation.width > 30 { controller.flipBackward() }
                }
            : nil
        )
    }
}
