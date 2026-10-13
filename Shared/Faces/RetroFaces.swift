import SwiftUI

private let neonPink = Color(red: 1, green: 0.18, blue: 0.68)
private let neonCyan = Color(red: 0.2, green: 0.95, blue: 1)
private let terminalGreen = Color(red: 0.2, green: 1, blue: 0.4)
private let lcdInk = Color(red: 0.12, green: 0.16, blue: 0.08)

struct NeonFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(neonCyan, lineWidth: 2)
                .shadow(color: neonCyan, radius: 4)
                .shadow(color: neonCyan, radius: 10)
            VStack(spacing: 6) {
                Text(time.text)
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: neonPink, radius: 2)
                    .shadow(color: neonPink, radius: 6)
                    .shadow(color: neonPink, radius: 14)
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .kerning(2)
                    .foregroundStyle(neonCyan)
                    .textCase(.uppercase)
                    .shadow(color: neonCyan, radius: 6)
            }
            .padding(8)
        }
    }
}

struct LCDFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Text(time.ampm ?? "24H")
                Spacer()
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .textCase(.uppercase)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(lcdInk.opacity(0.8))
            ZStack(alignment: .trailing) {
                Text("88:88").foregroundStyle(lcdInk.opacity(0.08))
                Text("\(time.hourPadded):\(time.minute)").foregroundStyle(lcdInk)
            }
            .font(.system(size: 44, weight: .bold, design: .monospaced))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            Text(date, format: .dateTime.day(.twoDigits).month(.twoDigits).year())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(lcdInk.opacity(0.7))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.62, green: 0.7, blue: 0.5).shadow(.inner(color: .black.opacity(0.5), radius: 3)))
        )
    }
}

struct TerminalFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(alignment: .leading, spacing: 4) {
            Text("duo:~$ now")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(terminalGreen.opacity(0.6))
            HStack(alignment: .bottom, spacing: 3) {
                Text(time.text)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Rectangle()
                    .frame(width: 10, height: 26)
                    .padding(.bottom, 6)
            }
            .foregroundStyle(terminalGreen)
            .shadow(color: terminalGreen.opacity(0.6), radius: 6)
            Text(date, format: .iso8601.year().month().day())
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(terminalGreen.opacity(0.8))
            Text(time.ampm.map { "mode: \($0)" } ?? "mode: 24h")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(terminalGreen.opacity(0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct SynthwaveFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.85, blue: 0.3), Color(red: 1, green: 0.25, blue: 0.55)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .mask { SunStripes() }
                    .frame(width: 92, height: 92)
                    .offset(y: 16)
                Text(time.text)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .italic()
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: neonPink, radius: 4)
                    .shadow(color: neonPink, radius: 10)
            }
            .frame(maxHeight: .infinity)
            PerspectiveGrid()
                .stroke(Color(red: 1, green: 0.35, blue: 0.85).opacity(0.85), lineWidth: 1)
                .frame(height: 36)
                .padding(.horizontal, -12)
                .padding(.bottom, -12)
        }
    }
}
