import XCTest

final class MusicLibraryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestingLibraryDemo"]
        app.launch()
    }

    func testLibraryOpensFromJamDial() throws {
        let openButton = app.buttons["library.open"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 5))

        openButton.tap()

        let sheet = app.otherElements["library.sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        let firstRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.'")
        ).firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["library.trackCount"].exists)
    }

    func testLibrarySearchFiltersTracks() throws {
        openLibrary()

        let searchField = app.textFields["library.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("jazz")

        let jazzRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.' AND label CONTAINS[c] 'jazz'")
        ).firstMatch
        XCTAssertTrue(jazzRow.waitForExistence(timeout: 2))

        let rockRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.' AND label CONTAINS[c] 'rock'")
        ).firstMatch
        XCTAssertFalse(rockRow.exists)
    }

    func testLibraryExpandsOnHeaderDrag() throws {
        openLibrary()

        let sheet = app.otherElements["library.sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        let start = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        let end = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02))
        start.press(forDuration: 0.05, thenDragTo: end)

        XCTAssertTrue(sheet.exists)
    }

    func testLibraryRowTapDismissesSheet() throws {
        openLibrary()

        let firstRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'library.row.'")
        ).firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 3))

        firstRow.tap()

        XCTAssertFalse(app.otherElements["library.sheet"].waitForExistence(timeout: 2))
    }

    func testLibraryCloseButtonDismissesSheet() throws {
        openLibrary()

        let close = app.buttons["library.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        close.tap()

        XCTAssertFalse(app.otherElements["library.sheet"].waitForExistence(timeout: 2))
    }

    func testLibraryTrackListScrolls() throws {
        openLibrary()

        let sheet = app.otherElements["library.sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        let start = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        let end = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        start.press(forDuration: 0.05, thenDragTo: end)

        let lastRow = app.buttons["library.row.6"]
        XCTAssertTrue(lastRow.waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    private func openLibrary() {
        let openButton = app.buttons["library.open"]
        XCTAssertTrue(openButton.waitForExistence(timeout: 5))
        openButton.tap()
        XCTAssertTrue(app.otherElements["library.sheet"].waitForExistence(timeout: 3))
    }
}
