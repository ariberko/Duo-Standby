import SwiftUI
import WidgetKit

// Lock Screen widgets. They are drawn in one tint by the system, so they use shapes and text only.

private struct LockedLabel: View {
    let pack: Pack

    var body: some View {
        Label(pack.title, systemImage: "lock.fill")
            .font(.system(size: 12, weight: .semibold))
    }
}

struct CountdownLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockCountdown", provider: DailyProvider(pack: .pro)) { entry in
            CountdownLockView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Countdown")
        .description("Days left until your big day, on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct CountdownLockView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: entry.date),
            to: calendar.startOfDay(for: entry.settings.countdownDate)
        ).day ?? 0
        let title = entry.settings.countdownTitle.isEmpty ? "Countdown" : entry.settings.countdownTitle
        if entry.isLocked {
            LockedLabel(pack: .pro)
        } else {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Text(verbatim: String(abs(days)))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                        Text("days")
                            .font(.system(size: 10, weight: .medium))
                    }
                }
            case .accessoryInline:
                Text(verbatim: "\(title): \(days) days")
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(verbatim: days == 0 ? "Today!" : "\(abs(days)) days \(days > 0 ? "to go" : "ago")")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct MoonLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockMoon", provider: DailyProvider(pack: .space)) { entry in
            MoonLockView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Moon Phase")
        .description("Tonight's moon on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct MoonLockView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let phase = MoonPhase.fraction(for: entry.date)
        if entry.isLocked {
            LockedLabel(pack: .space)
        } else if family == .accessoryCircular {
            ZStack {
                AccessoryWidgetBackground()
                ZStack {
                    Circle().fill(.white.opacity(0.2))
                    MoonLitShape(phase: phase).fill(.white)
                }
                .padding(8)
            }
        } else {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(.white.opacity(0.2))
                    MoonLitShape(phase: phase).fill(.white)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(MoonPhase.name(for: phase))
                        .font(.headline)
                        .lineLimit(1)
                    Text(verbatim: "\(Int((MoonPhase.illumination(phase) * 100).rounded()))% lit")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct NameTagLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockNameTag", provider: NameTagProvider()) { entry in
            NameTagLockView(tag: entry.tag)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Name Tag")
        .description("Your name or a short sign on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct NameTagLockView: View {
    let tag: NameTag
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if family == .accessoryInline {
            Text(verbatim: tag.subtitle.isEmpty ? tag.title : "\(tag.title) · \(tag.subtitle)")
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: tag.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if !tag.subtitle.isEmpty {
                    Text(verbatim: tag.subtitle)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct QuoteLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockQuote", provider: QuoteProvider()) { entry in
            Group {
                if entry.isLocked {
                    LockedLabel(pack: .pro)
                } else {
                    Text(verbatim: entry.text)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Quote")
        .description("A new line every hour on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenWidgets: WidgetBundle {
    var body: some Widget {
        CountdownLockWidget()
        MoonLockWidget()
        NameTagLockWidget()
        QuoteLockWidget()
    }
}
