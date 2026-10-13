import SwiftUI

struct GalaxyFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(spacing: 2) {
            Text(time.text)
                .font(.system(size: 50, weight: .light, design: settings.font.design))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.7, green: 0.4, blue: 1), radius: 10)
            Text(date, format: .dateTime.weekday(.wide).day())
                .font(.system(size: 13, weight: .medium, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct AuroraFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 13, weight: .semibold, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.75))
            Text(time.text)
                .font(.system(size: 48, weight: .bold, design: settings.font.design))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

struct NebulaFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(spacing: 4) {
            Text(time.hourPadded)
            Text(time.minute)
        }
        .font(.system(size: 46, weight: .heavy, design: settings.font.design))
        .monospacedDigit()
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 6)
    }
}

struct OrbitFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minute = Double(parts.minute ?? 0)
        let hour = Double((parts.hour ?? 0) % 12) + minute / 60
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outer = size / 2 * 0.92
            let inner = size / 2 * 0.6
            ZStack {
                orbit(radius: outer, center: center)
                orbit(radius: inner, center: center)
                Circle()
                    .fill(settings.accent)
                    .frame(width: 46, height: 46)
                    .shadow(color: settings.accent, radius: 10)
                    .position(center)
                Text(time.text)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .position(center)
                planet(color: Color(red: 0.3, green: 0.85, blue: 1), size: 14)
                    .position(point(center: center, radius: inner, fraction: hour / 12))
                planet(color: Color(red: 1, green: 0.4, blue: 0.7), size: 10)
                    .position(point(center: center, radius: outer, fraction: minute / 60))
            }
        }
    }

    private func orbit(radius: CGFloat, center: CGPoint) -> some View {
        Circle()
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
    }

    private func planet(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color, radius: 5)
    }

    private func point(center: CGPoint, radius: CGFloat, fraction: Double) -> CGPoint {
        let angle = fraction * 2 * .pi
        return CGPoint(x: center.x + radius * CGFloat(sin(angle)), y: center.y - radius * CGFloat(cos(angle)))
    }
}
