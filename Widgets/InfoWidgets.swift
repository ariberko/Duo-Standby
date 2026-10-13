import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Shared simple entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let settings: StudioSettings
    let isLocked: Bool
}

private func nextMidnight(after date: Date) -> Date {
    Calendar.current.nextDate(after: date, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? date.addingTimeInterval(3600)
}

/// A provider that shows one entry per date and asks for a refresh after the last one.
struct DailyProvider: TimelineProvider {
    let pack: Pack

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, settings: StudioSettings(), isLocked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry(.now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let now = Date.now
        completion(Timeline(entries: [makeEntry(now)], policy: .after(nextMidnight(after: now))))
    }

    private func makeEntry(_ date: Date) -> SimpleEntry {
        SimpleEntry(date: date, settings: .load(), isLocked: !Entitlements.isUnlocked(pack))
    }
}

// MARK: - Calendar

struct CalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.calendar, provider: DailyProvider(pack: .free)) { entry in
            CalendarFace(date: entry.date, settings: entry.settings)
                .padding(12)
                .containerBackground(for: .widget) {
                    StudioWidgetBackground(widget: .calendar, settings: entry.settings)
                }
        }
        .configurationDisplayName("Calendar")
        .description(StudioWidget.calendar.summary)
        .standByStyle()
    }
}

// MARK: - Battery

struct BatteryEntry: TimelineEntry {
    let date: Date
    let level: Float
    let isCharging: Bool
    let settings: StudioSettings
}

struct BatteryProvider: TimelineProvider {
    func placeholder(in context: Context) -> BatteryEntry {
        BatteryEntry(date: .now, level: 0.8, isCharging: true, settings: StudioSettings())
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryEntry) -> Void) {
        Task { @MainActor in completion(Self.readBattery()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryEntry>) -> Void) {
        Task { @MainActor in
            let entry = Self.readBattery()
            completion(Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(15 * 60))))
        }
    }

    @MainActor
    private static func readBattery() -> BatteryEntry {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let state = device.batteryState
        return BatteryEntry(
            date: .now,
            level: device.batteryLevel,
            isCharging: state == .charging || state == .full,
            settings: .load()
        )
    }
}

struct BatteryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.battery, provider: BatteryProvider()) { entry in
            BatteryFace(level: entry.level, isCharging: entry.isCharging, settings: entry.settings)
                .padding(12)
                .containerBackground(for: .widget) {
                    StudioWidgetBackground(widget: .battery, settings: entry.settings)
                }
        }
        .configurationDisplayName("Battery")
        .description(StudioWidget.battery.summary)
        .standByStyle()
    }
}

// MARK: - Moon (Space pack)

struct MoonWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.moon, provider: DailyProvider(pack: .space)) { entry in
            MoonFace(date: entry.date)
                .padding(14)
                .locked(entry.isLocked, pack: .space)
                .containerBackground(for: .widget) {
                    StudioWidgetBackground(widget: .moon, settings: entry.settings)
                }
        }
        .configurationDisplayName("Moon Phase")
        .description(StudioWidget.moon.summary)
        .standByStyle()
    }
}

// MARK: - Countdown (Pro pack)

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.countdown, provider: DailyProvider(pack: .pro)) { entry in
            CountdownFace(now: entry.date, settings: entry.settings)
                .padding(12)
                .locked(entry.isLocked, pack: .pro)
                .containerBackground(for: .widget) {
                    StudioWidgetBackground(widget: .countdown, settings: entry.settings)
                }
        }
        .configurationDisplayName("Countdown")
        .description(StudioWidget.countdown.summary)
        .standByStyle()
    }
}

// MARK: - Quote (Pro pack, interactive)

struct NextQuoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Quote"

    func perform() async throws -> some IntentResult {
        guard Entitlements.isUnlocked(.pro) else { return .result() }
        QuoteBook.advance()
        return .result()
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let text: String
    let settings: StudioSettings
    let isLocked: Bool
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: .now, text: QuoteBook.lines[0], settings: StudioSettings(), isLocked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(makeEntry(.now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let start = Calendar.current.dateInterval(of: .hour, for: .now)?.start ?? .now
        let entries = (0..<24).map { makeEntry(start.addingTimeInterval(Double($0) * 3600)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func makeEntry(_ date: Date) -> QuoteEntry {
        QuoteEntry(date: date, text: QuoteBook.quote(for: date), settings: .load(), isLocked: !Entitlements.isUnlocked(.pro))
    }
}

struct QuoteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.quote, provider: QuoteProvider()) { entry in
            ZStack(alignment: .bottomTrailing) {
                QuoteFace(text: entry.text, settings: entry.settings)
                if !entry.isLocked {
                    Button(intent: NextQuoteIntent()) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(entry.settings.accent, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .locked(entry.isLocked, pack: .pro)
            .containerBackground(for: .widget) {
                StudioWidgetBackground(widget: .quote, settings: entry.settings)
            }
        }
        .configurationDisplayName("Quote")
        .description(StudioWidget.quote.summary)
        .standByStyle()
    }
}

// MARK: - Photo clock (Pro pack)

struct PhotoEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let settings: StudioSettings
    let isLocked: Bool
}

struct PhotoProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhotoEntry {
        PhotoEntry(date: .now, image: nil, settings: StudioSettings(), isLocked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (PhotoEntry) -> Void) {
        completion(PhotoEntry(date: .now, image: PhotoStore.load(), settings: .load(), isLocked: !Entitlements.isUnlocked(.pro)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotoEntry>) -> Void) {
        let image = PhotoStore.load()
        let settings = StudioSettings.load()
        let isLocked = !Entitlements.isUnlocked(.pro)
        let entries = MinuteTimeline.dates().map { PhotoEntry(date: $0, image: image, settings: settings, isLocked: isLocked) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct PhotoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.photo, provider: PhotoProvider()) { entry in
            PhotoFace(image: entry.image, date: entry.date, settings: entry.settings)
                .locked(entry.isLocked, pack: .pro)
                .containerBackground(for: .widget) {
                    StudioWidgetBackground(widget: .photo, settings: entry.settings)
                }
        }
        .configurationDisplayName("Photo Clock")
        .description(StudioWidget.photo.summary)
        .standByStyle()
    }
}
