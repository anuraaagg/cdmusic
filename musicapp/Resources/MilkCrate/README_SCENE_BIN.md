# Milk crate 3D (`scene.gltf` + optional `scene.bin`)

The repo includes `scene.gltf` (Sketchfab “Milk Crate”, CC-BY-4.0 — see `license.txt`). The companion binary `scene.bin` is **not bundled** here because Sketchfab’s CDN requires authenticated download.

If you add `scene.bin` next to `scene.gltf` (same folder, 327 672 bytes matching the glTF buffer), `MilkCrateSceneController` loads the real mesh with holes.

Otherwise the app builds a **green procedural lattice crate** (open slats) so the feature works out of the box.

**To obtain `scene.bin`:** sign in at [sketchfab.com](https://sketchfab.com/3d-models/milk-crate-fb01473792a541b09cc0acc07ac3dbc1), download the original glTF archive, and copy `scene.bin` into this folder.
