import XCTest

/// Opens the Home Screen widget gallery, searches for the app and saves screenshots.
/// Used by the widget-check workflow to see whether our widgets show up.
final class WidgetGalleryUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    private var step = 0

    func testWidgetGalleryShowsApp() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-screenshotTab", "clocks"]
        app.launch()
        sleep(3)
        XCUIDevice.shared.press(.home)
        sleep(2)
        save("home")

        // Long-press an app icon to get "Edit Home Screen", or empty space to jiggle.
        let icon = springboard.icons.element(boundBy: 0)
        if icon.waitForExistence(timeout: 5) {
            icon.press(forDuration: 1.5)
        } else {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2)
        }
        sleep(2)
        save("long-press")
        tapFirst(["Edit Home Screen"])
        sleep(2)
        tapFirst(["Edit"])
        sleep(1)
        tapFirst(["Add Widget", "Add widget", "+"])
        sleep(3)
        save("gallery")

        let search = springboard.searchFields.firstMatch
        if search.waitForExistence(timeout: 5) {
            search.tap()
            search.typeText("Duo")
            sleep(4)
        }
        save("search")
        print("===== SPRINGBOARD TREE =====")
        print(springboard.debugDescription)
    }

    private func tapFirst(_ labels: [String]) {
        for label in labels {
            let button = springboard.buttons[label]
            if button.exists && button.isHittable {
                button.tap()
                return
            }
        }
    }

    private func save(_ name: String) {
        step += 1
        let shot = XCUIScreen.main.screenshot()
        let dir = ProcessInfo.processInfo.environment["OUTPUT_DIR"] ?? NSTemporaryDirectory()
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(step)-\(name).png")
        try? shot.pngRepresentation.write(to: url)
    }
}
