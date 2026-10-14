import Foundation

/// Storage shared between the app and the widget extension.
enum AppGroup {
    static let id = "group.com.ariberkowitz.standbystudio"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}

enum WidgetKinds {
    static let clock = "ClockWidget"
    static let calendar = "CalendarWidget"
    static let moon = "MoonWidget"
    static let countdown = "CountdownWidget"
    static let quote = "QuoteWidget"
    static let photo = "PhotoWidget"
    static let nameTag = "NameTagWidget"
    static let live = "LiveWidget"
}
