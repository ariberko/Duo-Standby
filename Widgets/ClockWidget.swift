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
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .locked(entry.isLocked, pack: entry.style.pack)
            .containerBackground(for: .widget) {
                ClockBackground(style: entry.style, settings: entry.settings)
            }
    }

    @ViewBuilder
    private var content: some View {
        let face = ClockFaceView(style: entry.style, date: entry.date, settings: entry.settings)
        switch family {
        case .systemMedium:
            HStack(spacing: 16) {
                ScaledToFit { face }
                    .aspectRatio(1, contentMode: .fit)
                DatePanel(date: entry.date, settings: entry.settings)
            }
            .padding(12)
        case .systemLarge:
            ScaledToFit { face }
                .padding(20)
        default:
            face.padding(12)
        }
    }
}

/// The clock you can switch between all 15 styles with Edit Widget.
struct ClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.clock, intent: ClockStyleIntent.self, provider: ClockProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("Clock: Any Style")
        .description("Long-press it and tap Edit Widget to switch between all 15 styles.")
        .standByStyle([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - One widget per style, so every look shows up in the widget gallery

protocol FixedClockStyle {
    static var style: ClockStyle { get }
}

struct FixedClockProvider<S: FixedClockStyle>: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, style: S.style, settings: StudioSettings(), isLocked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(entries(for: [.now])[0])
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        completion(Timeline(entries: entries(for: MinuteTimeline.dates()), policy: .atEnd))
    }

    private func entries(for dates: [Date]) -> [ClockEntry] {
        let settings = StudioSettings.load()
        let isLocked = !Entitlements.isUnlocked(S.style.pack)
        return dates.map { ClockEntry(date: $0, style: S.style, settings: settings, isLocked: isLocked) }
    }
}

struct FixedClockWidget<S: FixedClockStyle>: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Clock-\(S.style.rawValue)", provider: FixedClockProvider<S>()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("\(S.style.title) Clock")
        .description(S.style.pack == .free ? "Free clock." : "Clock from the \(S.style.pack.title).")
        .standByStyle([.systemSmall, .systemMedium, .systemLarge])
    }
}

enum FlipStyle: FixedClockStyle { static var style: ClockStyle { .flip } }
enum MinimalStyle: FixedClockStyle { static var style: ClockStyle { .minimal } }
enum AnalogStyle: FixedClockStyle { static var style: ClockStyle { .analog } }
enum BoldStyle: FixedClockStyle { static var style: ClockStyle { .bold } }
enum NeonStyle: FixedClockStyle { static var style: ClockStyle { .neon } }
enum LCDStyle: FixedClockStyle { static var style: ClockStyle { .lcd } }
enum TerminalStyle: FixedClockStyle { static var style: ClockStyle { .terminal } }
enum SynthwaveStyle: FixedClockStyle { static var style: ClockStyle { .synthwave } }
enum GalaxyStyle: FixedClockStyle { static var style: ClockStyle { .galaxy } }
enum AuroraStyle: FixedClockStyle { static var style: ClockStyle { .aurora } }
enum NebulaStyle: FixedClockStyle { static var style: ClockStyle { .nebula } }
enum OrbitStyle: FixedClockStyle { static var style: ClockStyle { .orbit } }
enum WordsStyle: FixedClockStyle { static var style: ClockStyle { .words } }
enum BinaryStyle: FixedClockStyle { static var style: ClockStyle { .binary } }
enum StudioStyle: FixedClockStyle { static var style: ClockStyle { .studio } }

struct FreeAndRetroClocks: WidgetBundle {
    var body: some Widget {
        FixedClockWidget<FlipStyle>()
        FixedClockWidget<MinimalStyle>()
        FixedClockWidget<AnalogStyle>()
        FixedClockWidget<BoldStyle>()
        FixedClockWidget<NeonStyle>()
        FixedClockWidget<LCDStyle>()
        FixedClockWidget<TerminalStyle>()
        FixedClockWidget<SynthwaveStyle>()
    }
}

struct SpaceAndProClocks: WidgetBundle {
    var body: some Widget {
        FixedClockWidget<GalaxyStyle>()
        FixedClockWidget<AuroraStyle>()
        FixedClockWidget<NebulaStyle>()
        FixedClockWidget<OrbitStyle>()
        FixedClockWidget<WordsStyle>()
        FixedClockWidget<BinaryStyle>()
        FixedClockWidget<StudioStyle>()
        LockScreenWidgets().body
    }
}
