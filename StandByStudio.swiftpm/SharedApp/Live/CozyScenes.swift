import SwiftUI

// MARK: - Fireplace

struct FireplaceScene: View {
    let start: Date
    let paused: Bool

    var body: some View {
        TimelineView(.animation(paused: paused)) { context in
            let t = max(0, context.date.timeIntervalSince(start))
            Canvas { ctx, size in
                let rect = CGRect(origin: .zero, size: size)
                ctx.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [.black, Color(red: 0.12, green: 0.03, blue: 0.01)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
                ))
                let unit = min(size.width, size.height)
                let baseY = size.height * 0.82
                let cx = size.width / 2

                // Warm glow on the floor.
                let flicker = 0.85 + 0.15 * sin(t * 9) * sin(t * 3.7)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - unit * 0.7, y: baseY - unit * 0.45, width: unit * 1.4, height: unit * 0.9)),
                    with: .radialGradient(
                        Gradient(colors: [Color.orange.opacity(0.35 * flicker), .clear]),
                        center: CGPoint(x: cx, y: baseY), startRadius: 0, endRadius: unit * 0.7
                    )
                )

                // Flames: many soft blobs that rise, shrink and cool from yellow to red.
                ctx.drawLayer { layer in
                    layer.addFilter(.blur(radius: unit * 0.025))
                    layer.blendMode = .plusLighter
                    for i in 0..<80 {
                        var rng = SeededGenerator(seed: UInt64(i) &+ 77)
                        let spread = Double.random(in: -1...1, using: &rng)
                        let speed = Double.random(in: 0.5...0.9, using: &rng)
                        let phase = Double.random(in: 0...1, using: &rng)
                        let maxRadius = unit * CGFloat.random(in: 0.05...0.1, using: &rng)
                        let life = (t * speed + phase).truncatingRemainder(dividingBy: 1)
                        let sway = CGFloat(sin(t * 2.5 + phase * 12)) * unit * 0.03 * CGFloat(life)
                        let x = cx + CGFloat(spread) * unit * 0.28 * CGFloat(1 - life) + sway
                        let y = baseY - CGFloat(life) * unit * 0.6
                        let r = maxRadius * CGFloat(1 - life * 0.8)
                        let color: Color = life < 0.25
                            ? Color(red: 1, green: 0.9, blue: 0.5)
                            : life < 0.55 ? Color(red: 1, green: 0.55, blue: 0.1) : Color(red: 0.9, green: 0.2, blue: 0.05)
                        layer.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r * 1.4, width: r * 2, height: r * 2.8)),
                            with: .color(color.opacity(0.9 * (1 - life)))
                        )
                    }
                }

                // Logs.
                let logWidth = unit * 0.7
                let logHeight = unit * 0.09
                let logs: [(angle: Double, dy: CGFloat)] = [(-8, 0), (8, 0), (0, logHeight * 0.9)]
                for (angle, dy) in logs {
                    var log = ctx
                    log.translateBy(x: cx, y: baseY + dy)
                    log.rotate(by: .degrees(angle))
                    log.fill(
                        Path(roundedRect: CGRect(x: -logWidth / 2, y: -logHeight / 2, width: logWidth, height: logHeight), cornerRadius: logHeight / 2),
                        with: .linearGradient(
                            Gradient(colors: [Color(red: 0.35, green: 0.18, blue: 0.08), Color(red: 0.15, green: 0.07, blue: 0.03)]),
                            startPoint: CGPoint(x: 0, y: -logHeight / 2), endPoint: CGPoint(x: 0, y: logHeight / 2)
                        )
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Candle

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        path.move(to: top)
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: rect.maxX + rect.width * 0.15, y: rect.minY + rect.height * 0.6),
            control2: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addCurve(
            to: top,
            control1: CGPoint(x: rect.minX, y: rect.maxY),
            control2: CGPoint(x: rect.minX - rect.width * 0.15, y: rect.minY + rect.height * 0.6)
        )
        return path
    }
}

struct CandleScene: View {
    let start: Date
    let paused: Bool

    var body: some View {
        GeometryReader { geo in
            let unit = min(geo.size.width, geo.size.height)
            TimelineView(.animation(paused: paused)) { context in
                let t = max(0, context.date.timeIntervalSince(start))
                let flicker = sin(t * 13) * 0.04 + sin(t * 7.3) * 0.03 + sin(t * 23) * 0.02
                ZStack {
                    Color.black
                    RadialGradient(
                        colors: [Color.orange.opacity(0.35 + flicker), .clear],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 0, endRadius: unit * 0.6
                    )
                    VStack(spacing: unit * 0.01) {
                        ZStack(alignment: .bottom) {
                            FlameShape()
                                .fill(LinearGradient(
                                    colors: [Color(red: 1, green: 0.55, blue: 0.1), Color(red: 1, green: 0.9, blue: 0.5), .white],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .shadow(color: .orange, radius: unit * 0.04)
                            Capsule()
                                .fill(Color(red: 0.4, green: 0.6, blue: 1).opacity(0.6))
                                .frame(width: unit * 0.025, height: unit * 0.03)
                                .blur(radius: 2)
                        }
                        .frame(width: unit * 0.075, height: unit * 0.2 * CGFloat(1 + flicker * 2))
                        .rotationEffect(.degrees(flicker * 25), anchor: .bottom)
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .frame(width: 2, height: unit * 0.025)
                        RoundedRectangle(cornerRadius: unit * 0.015)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.98, green: 0.94, blue: 0.85), Color(red: 0.8, green: 0.74, blue: 0.62)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: unit * 0.16, height: unit * 0.38)
                    }
                    .offset(y: unit * 0.08)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Lava lamp

struct LavaLampScene: View {
    let start: Date
    let paused: Bool

    var body: some View {
        TimelineView(.animation(paused: paused)) { context in
            let t = max(0, context.date.timeIntervalSince(start))
            Canvas { ctx, size in
                let rect = CGRect(origin: .zero, size: size)
                ctx.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [Color(red: 0.25, green: 0.02, blue: 0.3), Color(red: 0.55, green: 0.05, blue: 0.2)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
                ))
                let unit = min(size.width, size.height)
                // Metaballs: blur the blobs, then keep only the solid middle so they melt together.
                ctx.addFilter(.alphaThreshold(min: 0.5, color: Color(red: 1, green: 0.45, blue: 0.2)))
                ctx.addFilter(.blur(radius: unit * 0.04))
                ctx.drawLayer { layer in
                    for i in 0..<8 {
                        var rng = SeededGenerator(seed: UInt64(i) &+ 300)
                        let xFraction = Double.random(in: 0.2...0.8, using: &rng)
                        let radius = unit * CGFloat.random(in: 0.07...0.14, using: &rng)
                        let speed = Double.random(in: 0.08...0.18, using: &rng)
                        let phase = Double.random(in: 0...(2 * .pi), using: &rng)
                        let y = (0.5 + 0.45 * sin(t * speed + phase)) * Double(size.height)
                        let x = (xFraction + 0.06 * sin(t * 0.3 + phase)) * Double(size.width)
                        layer.fill(
                            Path(ellipseIn: CGRect(x: CGFloat(x) - radius, y: CGFloat(y) - radius, width: radius * 2, height: radius * 2.2)),
                            with: .color(.black)
                        )
                    }
                    // Pools at the bottom and top of the lamp.
                    layer.fill(Path(ellipseIn: CGRect(x: -size.width * 0.1, y: size.height - unit * 0.12, width: size.width * 1.2, height: unit * 0.3)), with: .color(.black))
                    layer.fill(Path(ellipseIn: CGRect(x: -size.width * 0.1, y: -unit * 0.2, width: size.width * 1.2, height: unit * 0.28)), with: .color(.black))
                }
            }
        }
        .ignoresSafeArea()
    }
}
