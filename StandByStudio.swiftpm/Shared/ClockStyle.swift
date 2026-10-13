import SwiftUI

enum ClockStyle: String, CaseIterable, Codable, Identifiable {
    case flip, minimal, analog, bold
    case neon, lcd, terminal, synthwave
    case galaxy, aurora, nebula, orbit
    case words, binary, studio

    var id: String { rawValue }

    var pack: Pack {
        switch self {
        case .flip, .minimal, .analog, .bold: .free
        case .neon, .lcd, .terminal, .synthwave: .retro
        case .galaxy, .aurora, .nebula, .orbit: .space
        case .words, .binary, .studio: .pro
        }
    }

    var title: String {
        switch self {
        case .flip: "Flip"
        case .minimal: "Minimal"
        case .analog: "Analog"
        case .bold: "Bold"
        case .neon: "Neon"
        case .lcd: "LCD"
        case .terminal: "Terminal"
        case .synthwave: "Synthwave"
        case .galaxy: "Galaxy"
        case .aurora: "Aurora"
        case .nebula: "Nebula"
        case .orbit: "Orbit"
        case .words: "Word Clock"
        case .binary: "Binary"
        case .studio: "Studio"
        }
    }

    static func styles(in pack: Pack) -> [ClockStyle] {
        allCases.filter { $0.pack == pack }
    }
}

/// Non-clock widgets.
enum StudioWidget: String, CaseIterable, Identifiable {
    case calendar, battery, moon, countdown, quote, photo

    var id: String { rawValue }

    var pack: Pack {
        switch self {
        case .calendar, .battery: .free
        case .moon: .space
        case .countdown, .quote, .photo: .pro
        }
    }

    var title: String {
        switch self {
        case .calendar: "Calendar"
        case .battery: "Battery"
        case .moon: "Moon Phase"
        case .countdown: "Countdown"
        case .quote: "Quote"
        case .photo: "Photo Clock"
        }
    }

    var summary: String {
        switch self {
        case .calendar: "Today's date as a calendar page."
        case .battery: "Charge level with a glowing ring."
        case .moon: "Tonight's moon and how much is lit."
        case .countdown: "Days left until your big day."
        case .quote: "A new line every hour. Tap to shuffle."
        case .photo: "Your favorite photo with the time on top."
        }
    }

    var contentPadding: CGFloat { self == .photo ? 0 : 12 }
}
