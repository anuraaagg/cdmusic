#if DEBUG

enum MilkCrateStackLayoutTests {
    static func run() -> [String] {
        var failures: [String] = []

        let p0 = MilkCrateSleeveLayout.position(stackIndex: 0, frontIndex: 0, count: 4)
        let p1 = MilkCrateSleeveLayout.position(stackIndex: 1, frontIndex: 0, count: 4)
        if !(p0.z > p1.z) {
            failures.append("stack index 0 should sit forward of index 1 (+Z)")
        }

        let aligned = MilkCrateSleeveLayout.position(stackIndex: 1, frontIndex: 1, count: 4)
        let deltaZ = aligned.z - MilkCrateSleeveLayout.zFrontBaseline
        if abs(deltaZ) > 0.001 {
            failures.append("when frontIndex aligns, slot 1 should rest at baseline Z")
        }

        let sFront = MilkCrateSleeveLayout.sleeveScale(depthFromFrontHighlight: 0)
        let sBack = MilkCrateSleeveLayout.sleeveScale(depthFromFrontHighlight: 10)
        if !(sFront >= sBack) {
            failures.append("deeper records should not scale larger than the front record")
        }

        return failures
    }
}

#endif
