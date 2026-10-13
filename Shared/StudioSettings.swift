import SwiftUI

enum FontChoice: String, Codable, CaseIterable, Identifiable {
    case rounded, standard, serif, monospaced

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var design: Font.Design {
        switch self {
        case .rounded: .rounded
        case .standard: .default
        case .serif: .serif
        case .monospaced: .monospaced
        }
    }
}

/// User choices shared by every widget.
struct StudioSettings: Codable, Equatable {
    var accentHex = "#FF9F0A"
    var use24Hour = TimeParts.localePrefers24Hour
    var font: FontChoice = .rounded
    var countdownTitle = "Vacation"
    var countdownDate = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now

    var accent: Color { Color(hex: accentHex) }

    private static let key = "studioSettings"

    static func load() -> StudioSettings {
        guard let data = AppGroup.defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(StudioSettings.self, from: data)
        else { return StudioSettings() }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: Self.key)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(cleaned, radix: 16) ?? 0xFF9F0A
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        func byte(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
    }
}
