import Foundation

enum MoonPhase {
    private static let synodicMonth = 29.530588853
    /// A known new moon: 2000-01-06 18:14 UTC.
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)

    /// 0 = new moon, 0.5 = full moon, back to 1.
    static func fraction(for date: Date) -> Double {
        let days = date.timeIntervalSince(referenceNewMoon) / 86_400
        let phase = days.truncatingRemainder(dividingBy: synodicMonth) / synodicMonth
        return phase < 0 ? phase + 1 : phase
    }

    static func illumination(_ phase: Double) -> Double {
        (1 - cos(2 * .pi * phase)) / 2
    }

    static func name(for phase: Double) -> String {
        switch phase {
        case ..<0.03: "New Moon"
        case ..<0.22: "Waxing Crescent"
        case ..<0.28: "First Quarter"
        case ..<0.47: "Waxing Gibbous"
        case ..<0.53: "Full Moon"
        case ..<0.72: "Waning Gibbous"
        case ..<0.78: "Last Quarter"
        case ..<0.97: "Waning Crescent"
        default: "New Moon"
        }
    }
}
