import SwiftUI

struct CalendarFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.month(.wide))
                .font(.system(size: 15, weight: .bold, design: settings.font.design))
                .textCase(.uppercase)
                .foregroundStyle(settings.accent)
            Text(date, format: .dateTime.day())
                .font(.system(size: 72, weight: .bold, design: settings.font.design))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 15, weight: .medium, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BatteryFace: View {
    /// 0...1, or a negative number when unknown.
    let level: Float
    let isCharging: Bool
    let settings: StudioSettings

    private var fraction: Double { level < 0 ? 0 : Double(level) }
    private var color: Color { level >= 0 && level < 0.2 ? .red : .green }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 14)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 6)
            VStack(spacing: 2) {
                Image(systemName: isCharging ? "bolt.fill" : "iphone")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                Text(verbatim: level < 0 ? "--" : "\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 28, weight: .bold, design: settings.font.design))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .padding(6)
    }
}

/// The lit part of the moon for a phase between 0 (new) and 1.
struct MoonLitShape: Shape {
    let phase: Double

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let cx = rect.midX
        let cy = rect.midY
        let k = CGFloat(cos(2 * .pi * phase))
        let side: CGFloat = phase < 0.5 ? 1 : -1
        let steps = 40
        var path = Path()
        // Outer edge, top to bottom.
        for i in 0...steps {
            let theta = -Double.pi / 2 + Double.pi * Double(i) / Double(steps)
            let point = CGPoint(x: cx + side * r * CGFloat(cos(theta)), y: cy + r * CGFloat(sin(theta)))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        // Terminator, bottom back to top.
        for i in 0...steps {
            let theta = Double.pi / 2 - Double.pi * Double(i) / Double(steps)
            path.addLine(to: CGPoint(x: cx + side * r * k * CGFloat(cos(theta)), y: cy + r * CGFloat(sin(theta))))
        }
        path.closeSubpath()
        return path
    }
}

struct MoonFace: View {
    let date: Date

    var body: some View {
        let phase = MoonPhase.fraction(for: date)
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color(white: 0.14))
                MoonLitShape(phase: phase)
                    .fill(LinearGradient(colors: [Color(white: 0.98), Color(red: 0.85, green: 0.85, blue: 0.76)], startPoint: .top, endPoint: .bottom))
            }
            .aspectRatio(1, contentMode: .fit)
            .shadow(color: .white.opacity(0.25), radius: 10)
            Text(MoonPhase.name(for: phase))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Text(verbatim: "\(Int((MoonPhase.illumination(phase) * 100).rounded()))% lit")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

struct CountdownFace: View {
    let now: Date
    let settings: StudioSettings

    private var dayCount: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: settings.countdownDate)
        ).day ?? 0
    }

    var body: some View {
        let days = dayCount
        VStack(spacing: 2) {
            Text(settings.countdownTitle.isEmpty ? "Countdown" : settings.countdownTitle)
                .font(.system(size: 14, weight: .semibold, design: settings.font.design))
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.85))
            if days == 0 {
                Text("Today!")
                    .font(.system(size: 40, weight: .heavy, design: settings.font.design))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(settings.accent)
            } else {
                Text("\(abs(days))")
                    .font(.system(size: 64, weight: .heavy, design: settings.font.design))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .foregroundStyle(settings.accent)
                Text(label(for: days))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Text(settings.countdownDate, format: .dateTime.day().month(.abbreviated).year())
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func label(for days: Int) -> String {
        switch days {
        case 1: "day to go"
        case 2...: "days to go"
        case -1: "day ago"
        default: "days ago"
        }
    }
}

struct QuoteFace: View {
    let text: String
    let settings: StudioSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(settings.accent)
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: settings.font.design))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(5)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct PhotoFace: View {
    let image: UIImage?
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        ZStack(alignment: .bottomLeading) {
            if let image {
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 30))
                    Text("Pick a photo in the app")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 0) {
                Text(time.text)
                    .font(.system(size: 34, weight: .bold, design: settings.font.design))
                    .monospacedDigit()
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.system(size: 12, weight: .semibold, design: settings.font.design))
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .padding(12)
        }
    }
}

struct StudioWidgetBackground: View {
    let widget: StudioWidget
    let settings: StudioSettings

    var body: some View {
        switch widget {
        case .calendar, .quote:
            Color(white: 0.08)
        case .battery, .photo:
            Color.black
        case .moon:
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.07)
                Starfield(count: 35, seed: 11)
            }
        case .countdown:
            LinearGradient(colors: [settings.accent.opacity(0.35), .black], startPoint: .top, endPoint: .bottom)
        }
    }
}
