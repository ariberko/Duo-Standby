import SwiftUI

/// Draws content at its small-widget size, then scales it up to fill a bigger square.
/// The faces use fixed font sizes, so this keeps them looking right in medium and large widgets.
struct ScaledToFit<Content: View>: View {
    var base: CGFloat = 134
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            content
                .frame(width: base, height: base)
                .scaleEffect(side / base)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Weekday, day and month, for the right side of medium clock widgets.
struct DatePanel: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 15, weight: .bold, design: settings.font.design))
                .textCase(.uppercase)
                .foregroundStyle(settings.accent)
            Text(date, format: .dateTime.day())
                .font(.system(size: 52, weight: .bold, design: settings.font.design))
                .foregroundStyle(.white)
            Text(date, format: .dateTime.month(.wide).year())
                .font(.system(size: 14, weight: .medium, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.7))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small month calendar with today highlighted.
struct MonthGrid: View {
    let date: Date
    let accent: Color

    var body: some View {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let days = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let today = calendar.component(.day, from: date)
        let cells = Array(repeating: 0, count: offset) + Array(1...days)
        let rows = (cells.count + 6) / 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first...] + symbols[..<first])

        VStack(spacing: 2) {
            Text(date, format: .dateTime.month(.wide))
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 0) {
                ForEach(ordered.indices, id: \.self) { i in
                    Text(ordered[i])
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let index = row * 7 + column
                        let day = index < cells.count ? cells[index] : 0
                        Text(verbatim: day == 0 ? " " : String(day))
                            .font(.system(size: 10, weight: day == today ? .bold : .regular))
                            .foregroundStyle(day == today ? Color.black : Color.white)
                            .frame(maxWidth: .infinity)
                            .background {
                                if day == today {
                                    Circle().fill(accent).frame(width: 17, height: 17)
                                }
                            }
                    }
                }
            }
        }
    }
}

/// Phase name, how much is lit, and when the next full and new moons are.
struct MoonDetails: View {
    let date: Date

    var body: some View {
        let phase = MoonPhase.fraction(for: date)
        let cycle = 29.530588853
        let toFull = Int(((phase < 0.5 ? 0.5 : 1.5) - phase) * cycle)
        let toNew = Int((1 - phase) * cycle)
        VStack(alignment: .leading, spacing: 6) {
            Text(MoonPhase.name(for: phase))
                .font(.system(size: 17, weight: .bold))
            Text(verbatim: "\(Int((MoonPhase.illumination(phase) * 100).rounded()))% lit")
                .font(.system(size: 13))
                .opacity(0.7)
            Label(toFull == 0 ? "Full moon tonight" : "Full moon in \(toFull)d", systemImage: "circle.fill")
                .font(.system(size: 12, weight: .medium))
            Label(toNew == 0 ? "New moon tonight" : "New moon in \(toNew)d", systemImage: "circle")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Title, weeks and days left, and the date, for the medium countdown.
struct CountdownDetails: View {
    let now: Date
    let settings: StudioSettings

    var body: some View {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: settings.countdownDate)).day ?? 0
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.countdownTitle.isEmpty ? "Countdown" : settings.countdownTitle)
                .font(.system(size: 17, weight: .bold, design: settings.font.design))
                .lineLimit(2)
            if days > 6 {
                Text(verbatim: "\(days / 7) weeks, \(days % 7) days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(settings.accent)
            }
            Text(settings.countdownDate, format: .dateTime.weekday(.wide).day().month(.wide).year())
                .font(.system(size: 12))
                .opacity(0.7)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
