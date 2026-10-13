import AppIntents
import SwiftUI
import WidgetKit

extension ClockStyle: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Clock Style"

    static var caseDisplayRepresentations: [ClockStyle: DisplayRepresentation] = [
        .flip: "Flip",
        .minimal: "Minimal",
        .analog: "Analog",
        .bold: "Bold",
        .neon: "Neon (Retro)",
        .lcd: "LCD (Retro)",
        .terminal: "Terminal (Retro)",
        .synthwave: "Synthwave (Retro)",
        .galaxy: "Galaxy (Space)",
        .aurora: "Aurora (Space)",
        .nebula: "Nebula (Space)",
        .orbit: "Orbit (Space)",
        .words: "Word Clock (Pro)",
        .binary: "Binary (Pro)",
        .studio: "Studio (Pro)",
    ]
}

struct ClockStyleIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Clock Style"
    static var description = IntentDescription("Choose how your StandBy clock looks.")

    @Parameter(title: "Style", default: .flip)
    var style: ClockStyle
}

struct ClockEntry: TimelineEntry {
    let date: Date
    let style: ClockStyle
    let settings: StudioSettings
    let isLocked: Bool
}

struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, style: .flip, settings: StudioSettings(), isLocked: false)
    }

    func snapshot(for configuration: ClockStyleIntent, in context: Context) async -> ClockEntry {
        entries(for: configuration, dates: [.now])[0]
    }

    func timeline(for configuration: ClockStyleIntent, in context: Context) async -> Timeline<ClockEntry> {
        Timeline(entries: entries(for: configuration, dates: MinuteTimeline.dates()), policy: .atEnd)
    }

    private func entries(for configuration: ClockStyleIntent, dates: [Date]) -> [ClockEntry] {
        let settings = StudioSettings.load()
        let isLocked = !Entitlements.isUnlocked(configuration.style.pack)
        return dates.map { ClockEntry(date: $0, style: configuration.style, settings: settings, isLocked: isLocked) }
    }
}

struct ClockWidgetView: View {
    let entry: ClockEntry

    var body: some View {
        ClockFaceView(style: entry.style, date: entry.date, settings: entry.settings)
            .padding(12)
            .locked(entry.isLocked, pack: entry.style.pack)
            .containerBackground(for: .widget) {
                ClockBackground(style: entry.style, settings: entry.settings)
            }
    }
}

struct ClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.clock, intent: ClockStyleIntent.self, provider: ClockProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("StandBy Clock")
        .description("15 clock styles. Long-press and choose Edit Widget to switch.")
        .standByStyle()
    }
}
