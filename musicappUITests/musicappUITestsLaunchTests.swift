import XCTest

final class musicappUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestingLibraryDemo"]
        app.launch()
        XCTAssertTrue(app.buttons["library.open"].waitForExistence(timeout: 8))
    }
}
