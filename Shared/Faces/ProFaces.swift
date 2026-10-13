import SwiftUI

enum WordClock {
    private static let numbers = ["twelve", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]

    /// For example ("it's about", "quarter past", "ten").
    static func phrase(for date: Date) -> (lead: String, first: String, second: String) {
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        let rounded = Int((Double(m) / 5).rounded()) * 5
        let hour = numbers[(rounded > 30 ? h + 1 : h) % 12]
        let lead = m % 5 == 0 ? "it's" : "it's about"
        switch rounded {
        case 5: return (lead, "five past", hour)
        case 10: return (lead, "ten past", hour)
        case 15: return (lead, "quarter past", hour)
        case 20: return (lead, "twenty past", hour)
        case 25: return (lead, "twenty-five past", hour)
        case 30: return (lead, "half past", hour)
        case 35: return (lead, "twenty-five to", hour)
        case 40: return (lead, "twenty to", hour)
        case 45: return (lead, "quarter to", hour)
        case 50: return (lead, "ten to", hour)
        case 55: return (lead, "five to", hour)
        default: return (lead, hour, "o'clock")
        }
    }
}

struct WordsFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let phrase = WordClock.phrase(for: date)
        VStack(alignment: .leading, spacing: 2) {
            Text(phrase.lead.uppercased())
                .font(.system(size: 13, weight: .bold, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.45))
            Group {
                Text(phrase.first.uppercased())
                    .foregroundStyle(.white)
                Text(phrase.second.uppercased())
                    .foregroundStyle(settings.accent)
            }
            .font(.system(size: 28, weight: .heavy, design: settings.font.design))
            .minimumScaleFactor(0.5)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct BinaryFace: View {
    let date: Date
    let settings: StudioSettings

    private let bitsPerColumn = [2, 4, 3, 4]

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        let parsed = Array(time.hourPadded + time.minute).compactMap(\.wholeNumberValue)
        let digits = parsed.count == 4 ? parsed : [0, 0, 0, 0]
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { column in
                VStack(spacing: 6) {
                    ForEach([3, 2, 1, 0], id: \.self) { bit in
                        dot(isOn: (digits[column] >> bit) & 1 == 1)
                            .opacity(bit < bitsPerColumn[column] ? 1 : 0)
                    }
                    Text("\(digits[column])")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.leading, column == 2 ? 8 : 0)
            }
        }
    }

    private func dot(isOn: Bool) -> some View {
        Circle()
            .fill(isOn ? settings.accent : Color.white.opacity(0.1))
            .frame(width: 18, height: 18)
            .shadow(color: isOn ? settings.accent.opacity(0.8) : .clear, radius: 5)
    }
}

struct StudioFace: View {
    let date: Date
    let settings: StudioSettings

    var body: some View {
        let time = TimeParts(date: date, use24Hour: settings.use24Hour)
        VStack(alignment: .leading, spacing: 0) {
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 14, weight: .semibold, design: settings.font.design))
                .foregroundStyle(settings.accent)
            Spacer(minLength: 0)
            Text(time.text)
                .font(.system(size: 54, weight: .bold, design: settings.font.design))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(LinearGradient(colors: [.white, settings.accent], startPoint: .top, endPoint: .bottom))
            Text(date, format: .dateTime.month(.wide).day())
                .font(.system(size: 13, weight: .medium, design: settings.font.design))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
