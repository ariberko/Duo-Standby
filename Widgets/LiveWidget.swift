import AppIntents
import SwiftUI
import WidgetKit

extension LiveScene: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Live Scene"

    static var caseDisplayRepresentations: [LiveScene: DisplayRepresentation] = [
        .dvd: "DVD Bounce",
        .matrix: "Matrix Rain",
        .starfield: "Starfield",
        .mystify: "Mystify",
        .ledScroller: "LED Scroller",
        .talkTimer: "Talk Timer",
        .nowServing: "Now Serving",
        .fireplace: "Fireplace",
        .candle: "Candle",
        .lavaLamp: "Lava Lamp",
    ]
}

struct LiveSceneIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Live Scene"
    static var description = IntentDescription("Choose which scene opens when you tap the widget.")

    @Parameter(title: "Scene", default: .dvd)
    var scene: LiveScene
}

struct LiveEntry: TimelineEntry {
    let date: Date
    let scene: LiveScene
    let isLocked: Bool
}

struct LiveProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LiveEntry {
        LiveEntry(date: .now, scene: .dvd, isLocked: false)
    }

    func snapshot(for configuration: LiveSceneIntent, in context: Context) async -> LiveEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: LiveSceneIntent, in context: Context) async -> Timeline<LiveEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .never)
    }

    private func entry(for configuration: LiveSceneIntent) -> LiveEntry {
        LiveEntry(date: .now, scene: configuration.scene, isLocked: !Entitlements.isUnlocked(configuration.scene.pack))
    }
}

/// A launcher: widgets can't animate, so tapping this opens the scene full screen in the app.
struct LiveWidgetView: View {
    let entry: LiveEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let content = card
            .containerBackground(for: .widget) {
                LinearGradient(colors: entry.scene.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        if entry.isLocked {
            content.locked(true, pack: entry.scene.pack)
        } else {
            content.widgetURL(entry.scene.url)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.scene.symbol)
                    .font(.system(size: family == .systemMedium ? 40 : 34, weight: .semibold))
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
            Text(entry.scene.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(family == .systemMedium ? entry.scene.summary : "Tap to play")
                .font(.system(size: 12, weight: .medium))
                .opacity(0.75)
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(14)
    }
}

struct LiveWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetKinds.live, intent: LiveSceneIntent.self, provider: LiveProvider()) { entry in
            LiveWidgetView(entry: entry)
        }
        .configurationDisplayName("Live Scene")
        .description("Tap to open a full screen scene like DVD Bounce or Fireplace. Long-press and Edit Widget to pick one.")
        .standByStyle([.systemSmall, .systemMedium])
    }
}
