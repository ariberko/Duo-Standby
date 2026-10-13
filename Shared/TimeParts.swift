import Foundation

/// Splits a date into the strings the clock faces draw.
struct TimeParts {
    let hour: String
    let hourPadded: String
    let minute: String
    let ampm: String?

    var text: String { "\(hour):\(minute)" }

    init(date: Date, use24Hour: Bool, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        var h = parts.hour ?? 0
        let m = parts.minute ?? 0
        if use24Hour {
            ampm = nil
            hour = String(format: "%02d", h)
        } else {
            ampm = h < 12 ? "AM" : "PM"
            h = h % 12
            if h == 0 { h = 12 }
            hour = String(h)
        }
        hourPadded = String(format: "%02d", h)
        minute = String(format: "%02d", m)
    }

    static var localePrefers24Hour: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return !format.contains("a")
    }
}

enum MinuteTimeline {
    /// Dates at the start of each of the next `count` minutes.
    static func dates(count: Int = 60, from now: Date = .now) -> [Date] {
        let start = Calendar.current.dateInterval(of: .minute, for: now)?.start ?? now
        return (0..<count).map { start.addingTimeInterval(Double($0) * 60) }
    }
}
