import SwiftUI

/// Deterministic random numbers so stars stay in the same place every minute.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct Starfield: View {
    var count: Int = 50
    var seed: UInt64 = 7

    struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(Self.stars(count: count, seed: seed)) { star in
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
            }
        }
    }

    static func stars(count: Int, seed: UInt64) -> [Star] {
        var rng = SeededGenerator(seed: seed)
        var stars: [Star] = []
        for i in 0..<count {
            stars.append(Star(
                id: i,
                x: CGFloat.random(in: 0...1, using: &rng),
                y: CGFloat.random(in: 0...1, using: &rng),
                size: CGFloat.random(in: 0.8...2.4, using: &rng),
                opacity: Double.random(in: 0.3...1, using: &rng)
            ))
        }
        return stars
    }
}

struct Scanlines: Shape {
    var spacing: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.minY
        while y < rect.maxY {
            path.addRect(CGRect(x: rect.minX, y: y, width: rect.width, height: 1))
            y += spacing
        }
        return path
    }
}

/// Cuts the classic retro stripes out of the lower half of the sun.
struct SunStripes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.55))
        var y = rect.minY + rect.height * 0.58
        var height = rect.height * 0.08
        var gap = rect.height * 0.02
        while y < rect.maxY {
            path.addRect(CGRect(x: rect.minX, y: y, width: rect.width, height: height))
            y += height + gap
            height *= 0.8
            gap *= 1.4
        }
        return path
    }
}

struct PerspectiveGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let vanishing = CGPoint(x: rect.midX, y: rect.minY)
        for i in -6...6 {
            path.move(to: vanishing)
            path.addLine(to: CGPoint(x: rect.midX + CGFloat(i) * rect.width / 4, y: rect.maxY))
        }
        var t: CGFloat = 0.06
        while t < 1 {
            let y = rect.minY + rect.height * t
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            t *= 1.7
        }
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
