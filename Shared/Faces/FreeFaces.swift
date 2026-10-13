import SwiftUI

struct FlipFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                FlipCard(text: time.hourPadded)
                FlipCard(text: time.minute)
            }
            .frame(height: 88)
            .overlay(alignment: .bottomLeading) {
                if let ampm = time.ampm {
                    Text(ampm)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(5)
                }
            }
            Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.system(size: 13, weight: .semibold, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct FlipCard: View {
    let text: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.2), Color(white: 0.11)], startPoint: .top, endPoint: .bottom))
            Text(text)
                .font(.system(size: 60, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Color(white: 0.95))
                .padding(.horizontal, 4)
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .frame(height: 2)
        }
    }
}

struct MinimalFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(time.text)
                    .font(.system(size: 56, weight: .thin, design: settings.font.design))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let ampm = time.ampm {
                    Text(ampm).font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundStyle(.white)
            Capsule()
                .fill(settings.accent)
                .frame(width: 24, height: 3)
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 13, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

struct AnalogFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minute = Double(parts.minute ?? 0)
        let hour = Double((parts.hour ?? 0) % 12) + minute / 60
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            ZStack {
                Circle().fill(Color(white: 0.09))
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                ForEach(0..<60, id: \.self) { i in
                    let major = i % 5 == 0
                    let length = radius * (major ? 0.13 : 0.06)
                    Rectangle()
                        .fill(major ? Color.white : Color.white.opacity(0.35))
                        .frame(width: major ? 2 : 1, height: length)
                        .offset(y: -(radius * 0.92 - length / 2))
                        .rotationEffect(.degrees(Double(i) * 6))
                }
                hand(length: radius * 0.5, width: 4.5, color: .white)
                    .rotationEffect(.degrees(hour * 30))
                hand(length: radius * 0.76, width: 2.5, color: .white)
                    .rotationEffect(.degrees(minute * 6))
                Circle()
                    .fill(settings.accent)
                    .frame(width: 8, height: 8)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
    }
}

struct BoldFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(alignment: .leading, spacing: -14) {
            Text(time.hourPadded).foregroundStyle(settings.accent)
            Text(time.minute).foregroundStyle(.white)
        }
        .font(.system(size: 72, weight: .black, design: settings.font.design))
        .monospacedDigit()
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(date, format: .dateTime.weekday(.abbreviated))
                Text(date, format: .dateTime.day())
                if let ampm = time.ampm { Text(ampm) }
            }
            .font(.system(size: 13, weight: .bold, design: settings.font.design))
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.6))
        }
    }
}
