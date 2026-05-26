import XCTest

/// After a **long press** (~0.45s) on a carousel vinyl or the hero CD, `FigmaCrateDropSheet` appears with:
/// - `crate.dropSheet` — sheet container
/// - `crate.drop.cancel` — close control
/// - `crate.drop.vinyl` — draggable save target
final class SavedCrateUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestingLibraryDemo"]
        app.launch()
    }

    func testSavedCrateOpensFromCratesHeader() throws {
        revealCratesDrawer()
        let openButton = app.buttons["savedCrate.open"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 8))
        openButton.tap()
        XCTAssertTrue(app.otherElements["savedCrate.web"].waitForExistence(timeout: 3))
    }

    func testSavedCrateDismissesWithBack() throws {
        revealCratesDrawer()
        app.buttons["savedCrate.open"].tap()
        XCTAssertTrue(app.otherElements["savedCrate.web"].waitForExistence(timeout: 3))
        app.buttons["savedCrate.close"].tap()
        XCTAssertFalse(app.otherElements["savedCrate.web"].waitForExistence(timeout: 2))
    }

    func testSavedCrateModeToggle() throws {
        revealCratesDrawer()
        app.buttons["savedCrate.open"].tap()
        XCTAssertTrue(app.otherElements["savedCrate.web"].waitForExistence(timeout: 3))

        app.buttons["savedCrate.mode.crate"].tap()
        XCTAssertTrue(app.otherElements["savedCrate.crateTab"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.otherElements["savedCrate.web"].exists)
    }

    private func revealCratesDrawer() {
        let groove = app.otherElements["controlPanel.groove"]
        XCTAssertTrue(groove.waitForExistence(timeout: 8))
        let start = groove.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 0, dy: 280))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}
