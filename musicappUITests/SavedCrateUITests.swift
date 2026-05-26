import XCTest

final class SavedCrateUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestingLibraryDemo"]
        app.launch()
    }

    func testSavedCrateOpensFromJamRail() throws {
        let openButton = app.buttons["savedCrate.open"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 8))
        openButton.tap()
        XCTAssertTrue(app.staticTexts["My Crate"].waitForExistence(timeout: 3))
    }

    func testSavedCrateDismissesWithBack() throws {
        app.buttons["savedCrate.open"].tap()
        XCTAssertTrue(app.staticTexts["My Crate"].waitForExistence(timeout: 3))
        app.buttons["savedCrate.close"].tap()
        XCTAssertFalse(app.staticTexts["My Crate"].waitForExistence(timeout: 2))
    }
}
