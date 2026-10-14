import SwiftUI

/// Full screen animated scenes. They live in the app (not widgets), because widgets can't animate.
enum LiveScene: String, CaseIterable, Identifiable {
    case dvd, matrix, starfield, mystify
    case ledScroller, talkTimer, nowServing
    case fireplace, candle, lavaLamp

    var id: String { rawValue }

    enum Group: String, CaseIterable, Identifiable {
        case retro, signs, cozy

        var id: String { rawValue }

        var title: String {
            switch self {
            case .retro: "Retro Screensavers"
            case .signs: "Smart Signs"
            case .cozy: "Cozy"
            }
        }
    }

    var group: Group {
        switch self {
        case .dvd, .matrix, .starfield, .mystify: .retro
        case .ledScroller, .talkTimer, .nowServing: .signs
        case .fireplace, .candle, .lavaLamp: .cozy
        }
    }

    var pack: Pack {
        group == .signs ? .free : .live
    }

    var title: String {
        switch self {
        case .dvd: "DVD Bounce"
        case .matrix: "Matrix Rain"
        case .starfield: "Starfield"
        case .mystify: "Mystify"
        case .ledScroller: "LED Scroller"
        case .talkTimer: "Talk Timer"
        case .nowServing: "Now Serving"
        case .fireplace: "Fireplace"
        case .candle: "Candle"
        case .lavaLamp: "Lava Lamp"
        }
    }

    var summary: String {
        switch self {
        case .dvd: "Bounces around and changes color. Wait for the corner!"
        case .matrix: "Green code falling down the screen."
        case .starfield: "Fly through space at warp speed."
        case .mystify: "Colorful twisting lines."
        case .ledScroller: "Your text sliding by like a shop sign."
        case .talkTimer: "Big countdown that turns red at the end."
        case .nowServing: "Tap to call the next number."
        case .fireplace: "A warm crackling fire."
        case .candle: "One gently flickering candle."
        case .lavaLamp: "Slow blobs rising and falling."
        }
    }
}

extension LiveScene {
    var symbol: String {
        switch self {
        case .dvd: "play.rectangle.fill"
        case .matrix: "chevron.left.forwardslash.chevron.right"
        case .starfield: "sparkles"
        case .mystify: "scribble"
        case .ledScroller: "textformat"
        case .talkTimer: "timer"
        case .nowServing: "number"
        case .fireplace: "flame.fill"
        case .candle: "flame"
        case .lavaLamp: "drop.fill"
        }
    }

    /// Two colors for the launcher widget's background.
    var colors: [Color] {
        switch self {
        case .dvd: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.5, green: 0.1, blue: 0.6)]
        case .matrix: [.black, Color(red: 0, green: 0.3, blue: 0.1)]
        case .starfield: [.black, Color(red: 0.1, green: 0.1, blue: 0.35)]
        case .mystify: [Color(red: 0.2, green: 0, blue: 0.3), Color(red: 0, green: 0.3, blue: 0.3)]
        case .ledScroller: [.black, Color(red: 0.4, green: 0.05, blue: 0.05)]
        case .talkTimer: [Color(red: 0, green: 0.25, blue: 0.1), .black]
        case .nowServing: [Color(red: 0.35, green: 0.05, blue: 0.05), .black]
        case .fireplace: [Color(red: 0.5, green: 0.15, blue: 0), .black]
        case .candle: [Color(red: 0.35, green: 0.2, blue: 0), .black]
        case .lavaLamp: [Color(red: 0.4, green: 0.05, blue: 0.4), Color(red: 0.7, green: 0.25, blue: 0.1)]
        }
    }

    var url: URL? { URL(string: "standbystudio://live/\(rawValue)") }
}
