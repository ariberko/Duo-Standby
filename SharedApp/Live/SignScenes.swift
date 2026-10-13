import SwiftUI

// MARK: - LED scroller

private struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Dark lines over the text so it looks like a grid of LEDs.
private struct LEDGrid: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let line = spacing * 0.3
        var x = rect.minX
        while x < rect.maxX {
            path.addRect(CGRect(x: x, y: rect.minY, width: line, height: rect.height))
            x += spacing
        }
        var y = rect.minY
        while y < rect.maxY {
            path.addRect(CGRect(x: rect.minX, y: y, width: rect.width, height: line))
            y += spacing
        }
        return path
    }
}

struct LEDScrollerScene: View {
    let start: Date
    let paused: Bool

    @AppStorage(LiveKeys.ledText) private var text = "WELCOME"
    @AppStorage(LiveKeys.ledColor) private var colorHex = "#FF3B30"
    @State private var textWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let color = Color(hex: colorHex)
            TimelineView(.animation(paused: paused)) { context in
                let t = max(0, context.date.timeIntervalSince(start))
                let travel = max(Double(geo.size.width + textWidth), 1)
                let x = geo.size.width - CGFloat((t * Double(h) * 0.8).truncatingRemainder(dividingBy: travel))
                Text(verbatim: text.isEmpty ? " " : text)
                    .font(.system(size: h * 0.55, weight: .heavy, design: .monospaced))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(color)
                    .shadow(color: color, radius: h * 0.03)
                    .background(GeometryReader { textGeo in
                        Color.clear.preference(key: TextWidthKey.self, value: textGeo.size.width)
                    })
                    .offset(x: x)
                    .frame(width: geo.size.width, height: h, alignment: .leading)
            }
            .onPreferenceChange(TextWidthKey.self) { textWidth = $0 }
            .overlay {
                LEDGrid(spacing: max(4, h * 0.025))
                    .fill(Color.black.opacity(0.7))
            }
            .clipped()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

// MARK: - Talk timer

struct TalkTimerScene: View {
    let showsControls: Bool

    @AppStorage(LiveKeys.timerMinutes) private var minutes = 5
    @State private var endDate: Date?
    @State private var pausedRemaining: TimeInterval?

    private var isRunning: Bool { endDate != nil }

    var body: some View {
        GeometryReader { geo in
            let h = min(geo.size.height, geo.size.width * 0.6)
            TimelineView(.periodic(from: .now, by: showsControls ? 0.25 : 3600)) { context in
                let remaining = remaining(at: context.date)
                let color = remaining > 60 ? Color.green : remaining > 0 ? Color.yellow : Color.red
                VStack(spacing: h * 0.04) {
                    Text(remaining > 0 ? "TIME LEFT" : "TIME'S UP")
                        .font(.system(size: h * 0.08, weight: .bold, design: .rounded))
                        .foregroundStyle(remaining > 0 ? Color.white.opacity(0.6) : Color.red)
                        .opacity(remaining > 0 || Int(context.date.timeIntervalSince1970 * 2) % 2 == 0 ? 1 : 0.3)
                    Text(verbatim: format(remaining))
                        .font(.system(size: h * 0.42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.5), radius: h * 0.03)
                    if showsControls {
                        controls(height: h)
                    }
                }
                .padding()
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func controls(height h: CGFloat) -> some View {
        HStack(spacing: 12) {
            if isRunning {
                Button("Pause", systemImage: "pause.fill") {
                    pausedRemaining = endDate.map { $0.timeIntervalSinceNow }
                    endDate = nil
                }
            } else {
                Button(pausedRemaining == nil ? "Start" : "Resume", systemImage: "play.fill") {
                    endDate = .now.addingTimeInterval(pausedRemaining ?? Double(minutes) * 60)
                    pausedRemaining = nil
                }
            }
            Button("+1 min", systemImage: "plus") {
                if let end = endDate {
                    endDate = end.addingTimeInterval(60)
                } else if let paused = pausedRemaining {
                    pausedRemaining = paused + 60
                } else {
                    minutes = min(minutes + 1, 180)
                }
            }
            Button("Reset", systemImage: "arrow.counterclockwise") {
                endDate = nil
                pausedRemaining = nil
            }
        }
        .buttonStyle(.bordered)
        .tint(.white)
        if !isRunning && pausedRemaining == nil {
            Stepper("\(minutes) min", value: $minutes, in: 1...180)
                .frame(maxWidth: 220)
                .foregroundStyle(.white)
        }
    }

    private func remaining(at date: Date) -> TimeInterval {
        if let endDate { return endDate.timeIntervalSince(date) }
        if let pausedRemaining { return pausedRemaining }
        return Double(minutes) * 60
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        let sign = total < 0 ? "-" : ""
        let value = abs(total)
        return String(format: "%@%d:%02d", sign, value / 60, value % 60)
    }
}

// MARK: - Now serving

struct NowServingScene: View {
    let showsControls: Bool

    @AppStorage(LiveKeys.servingNumber) private var number = 1

    private static let red = Color(red: 1, green: 0.23, blue: 0.19)

    var body: some View {
        GeometryReader { geo in
            let h = min(geo.size.height, geo.size.width * 0.6)
            VStack(spacing: h * 0.03) {
                Text("NOW SERVING")
                    .font(.system(size: h * 0.09, weight: .heavy, design: .rounded))
                    .kerning(h * 0.01)
                    .foregroundStyle(.white.opacity(0.7))
                Text(verbatim: String(number))
                    .font(.system(size: h * 0.5, weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
                    .foregroundStyle(Self.red)
                    .shadow(color: Self.red, radius: h * 0.04)
                if showsControls {
                    Text("Tap anywhere for the next number")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    HStack(spacing: 12) {
                        Button("Back", systemImage: "minus") { number = max(1, number - 1) }
                        Button("Reset", systemImage: "arrow.counterclockwise") { number = 1 }
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            }
            .padding()
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                if showsControls { number += 1 }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
