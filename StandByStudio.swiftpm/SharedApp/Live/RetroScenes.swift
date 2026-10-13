import SwiftUI

// MARK: - DVD bounce

struct DVDBounceScene: View {
    let start: Date
    let paused: Bool

    @AppStorage(LiveKeys.dvdText) private var text = "DVD"

    private static let colors: [Color] = [
        Color(red: 1, green: 0.23, blue: 0.19), .orange, .yellow, .green, .cyan,
        Color(red: 0.3, green: 0.5, blue: 1), .purple, .pink,
    ]

    var body: some View {
        GeometryReader { geo in
            let logoWidth = min(geo.size.width * 0.32, 260)
            let logoHeight = logoWidth * 0.5
            TimelineView(.animation(paused: paused)) { context in
                let t = max(0, context.date.timeIntervalSince(start))
                let speedX = Double(min(geo.size.width, geo.size.height)) * 0.3
                let speedY = speedX * 0.77
                let lengthX = Double(geo.size.width - logoWidth)
                let lengthY = Double(geo.size.height - logoHeight)
                let x = bounce(t * speedX, length: lengthX)
                let y = bounce(t * speedY, length: lengthY)
                let color = Self.colors[(x.bounces + y.bounces) % Self.colors.count]
                // When the last wall hit on each axis happened at almost the same moment, it hit a corner.
                let lastHitX = Double(x.bounces) * lengthX / speedX
                let lastHitY = Double(y.bounces) * lengthY / speedY
                let corner = x.bounces > 0 && y.bounces > 0
                    && abs(lastHitX - lastHitY) < 0.12
                    && t - max(lastHitX, lastHitY) < 2.5

                ZStack(alignment: .topLeading) {
                    Color.black
                    DVDLogo(text: text.isEmpty ? "DVD" : text, color: color)
                        .frame(width: logoWidth, height: logoHeight)
                        .offset(x: CGFloat(x.position), y: CGFloat(y.position))
                    if corner {
                        Text("CORNER!")
                            .font(.system(size: geo.size.height * 0.14, weight: .black, design: .rounded))
                            .foregroundStyle(color)
                            .shadow(color: color, radius: 20)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct DVDLogo: View {
    let text: String
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            VStack(spacing: h * 0.04) {
                Text(verbatim: text)
                    .font(.system(size: h * 0.6, weight: .black, design: .rounded))
                    .italic()
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                Capsule()
                    .frame(width: geo.size.width * 0.8, height: h * 0.22)
                    .overlay {
                        Text("VIDEO")
                            .font(.system(size: h * 0.16, weight: .heavy))
                            .kerning(h * 0.03)
                            .foregroundStyle(.black)
                    }
            }
            .foregroundStyle(color)
            .frame(width: geo.size.width, height: h)
        }
    }
}

// MARK: - Matrix rain

struct MatrixRainScene: View {
    let start: Date
    let paused: Bool

    private static let glyphs = Array("ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789").map(String.init)
    private static let green = Color(red: 0.2, green: 1, blue: 0.4)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: paused)) { context in
            let t = max(0, context.date.timeIntervalSince(start))
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                let cell: CGFloat = 18
                let columns = Int(size.width / cell) + 1
                let rows = Int(size.height / cell) + 1
                let trail = 16
                let cycle = Double(rows + trail)
                for column in 0..<columns {
                    var rng = SeededGenerator(seed: UInt64(column) &* 7919 &+ 17)
                    let speed = Double.random(in: 5...14, using: &rng)
                    let offset = Double.random(in: 0...cycle, using: &rng)
                    let head = Int((t * speed + offset).truncatingRemainder(dividingBy: cycle))
                    for k in 0..<trail {
                        let row = head - k
                        guard row >= 0, row < rows else { continue }
                        let index = (row * 31 + column * 17 + Int(t * 4) * (k == 0 ? 7 : 0)) % Self.glyphs.count
                        let color = k == 0 ? Color.white : Self.green.opacity(1 - Double(k) / Double(trail))
                        ctx.draw(
                            Text(Self.glyphs[index])
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundStyle(color),
                            at: CGPoint(x: CGFloat(column) * cell + cell / 2, y: CGFloat(row) * cell + cell / 2)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Starfield

struct StarfieldScene: View {
    let start: Date
    let paused: Bool

    var body: some View {
        TimelineView(.animation(paused: paused)) { context in
            let t = max(0, context.date.timeIntervalSince(start))
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let spread = max(size.width, size.height) * 0.12
                for i in 0..<320 {
                    var rng = SeededGenerator(seed: UInt64(i) &+ 1000)
                    let x = Double.random(in: -1...1, using: &rng)
                    let y = Double.random(in: -1...1, using: &rng)
                    let phase = Double.random(in: 0...1, using: &rng)
                    // Depth goes from 1 (far) to 0 (passing the camera).
                    let z = max(1 - (t * 0.3 + phase).truncatingRemainder(dividingBy: 1), 0.02)
                    let tailZ = min(z + 0.05, 1)
                    let head = CGPoint(x: center.x + CGFloat(x / z) * spread, y: center.y + CGFloat(y / z) * spread)
                    let tail = CGPoint(x: center.x + CGFloat(x / tailZ) * spread, y: center.y + CGFloat(y / tailZ) * spread)
                    var path = Path()
                    path.move(to: tail)
                    path.addLine(to: head)
                    ctx.stroke(
                        path,
                        with: .color(.white.opacity(min(1, (1 - z) * 1.3))),
                        style: StrokeStyle(lineWidth: CGFloat(0.5 + (1 - z) * 3), lineCap: .round)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Mystify

struct MystifyScene: View {
    let start: Date
    let paused: Bool

    var body: some View {
        TimelineView(.animation(paused: paused)) { context in
            let t = max(0, context.date.timeIntervalSince(start))
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                let echoes = 7
                for shape in 0..<2 {
                    let hue = (t * 0.04 + Double(shape) * 0.5).truncatingRemainder(dividingBy: 1)
                    for echo in 0..<echoes {
                        let time = t - Double(echo) * 0.07
                        var path = Path()
                        for vertex in 0..<4 {
                            var rng = SeededGenerator(seed: UInt64(shape * 10 + vertex) &+ 500)
                            let speedX = Double.random(in: 60...170, using: &rng)
                            let speedY = Double.random(in: 60...170, using: &rng)
                            let phaseX = Double.random(in: 0...2000, using: &rng)
                            let phaseY = Double.random(in: 0...2000, using: &rng)
                            let point = CGPoint(
                                x: bounce(time * speedX + phaseX, length: Double(size.width)).position,
                                y: bounce(time * speedY + phaseY, length: Double(size.height)).position
                            )
                            if vertex == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                        path.closeSubpath()
                        let color = Color(hue: hue, saturation: 0.9, brightness: 1)
                            .opacity(1 - Double(echo) / Double(echoes))
                        ctx.stroke(path, with: .color(color), lineWidth: 2)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
