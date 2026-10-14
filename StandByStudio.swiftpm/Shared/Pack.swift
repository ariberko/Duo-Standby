import Foundation

/// A group of styles sold together. `.free` is always unlocked.
enum Pack: String, CaseIterable, Codable, Identifiable {
    case free, retro, space, pro, live

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "Free"
        case .retro: "Retro Pack"
        case .space: "Space Pack"
        case .pro: "Pro Pack"
        case .live: "Live Pack"
        }
    }

    var tagline: String {
        switch self {
        case .free: "Flip, Minimal, Analog, Bold, Name Tag, Calendar, Battery, LED Scroller, Talk Timer and Now Serving."
        case .retro: "Neon, LCD, Terminal and Synthwave clocks."
        case .space: "Galaxy, Aurora, Nebula, Orbit and the Moon widget."
        case .pro: "Word Clock, Binary, Studio plus Countdown, Quote and Photo widgets."
        case .live: "DVD Bounce, Matrix, Starfield, Mystify, Fireplace, Candle and Lava Lamp."
        }
    }

    var symbol: String {
        switch self {
        case .free: "gift"
        case .retro: "gamecontroller"
        case .space: "sparkles"
        case .pro: "crown"
        case .live: "play.tv"
        }
    }

    var productID: String? {
        switch self {
        case .free: nil
        // The first ".retro" ID was deleted in App Store Connect, and deleted IDs can never be reused.
        case .retro: "com.ariberkowitz.standbystudio.retropack"
        default: "com.ariberkowitz.standbystudio.\(rawValue)"
        }
    }
}

enum StoreProducts {
    static let allAccess = "com.ariberkowitz.standbystudio.all"

    static var all: [String] {
        Pack.allCases.compactMap(\.productID) + [allAccess]
    }

    static func packs(for productID: String) -> Set<Pack> {
        if productID == allAccess { return Set(Pack.allCases.filter { $0 != .free }) }
        return Set(Pack.allCases.filter { $0.productID == productID })
    }
}

/// The app writes purchased packs here; the widgets only read them.
enum Entitlements {
    private static let key = "unlockedPacks"

    static func unlocked() -> Set<Pack> {
        let raw = AppGroup.defaults.stringArray(forKey: key) ?? []
        return Set(raw.compactMap(Pack.init(rawValue:))).union([.free])
    }

    static func isUnlocked(_ pack: Pack) -> Bool {
        unlocked().contains(pack)
    }

    static func save(_ packs: Set<Pack>) {
        AppGroup.defaults.set(packs.map(\.rawValue).sorted(), forKey: key)
    }
}
