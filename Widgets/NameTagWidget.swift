import SwiftUI
import WidgetKit

struct NameTagEntry: TimelineEntry {
    let date: Date
    let tag: NameTag
    let settings: StudioSettings
}

struct NameTagProvider: TimelineProvider {
    func placeholder(in context: Context) -> NameTagEntry {
        NameTagEntry(date: .now, tag: NameTag(), settings: StudioSettings())
    }

    func getSnapshot(in context: Context, completion: @escaping (NameTagEntry) -> Void) {
        completion(NameTagEntry(date: .now, tag: .load(), settings: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NameTagEntry>) -> Void) {
        // The app reloads this widget whenever the text changes.
        let entry = NameTagEntry(date: .now, tag: .load(), settings: .load())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(24 * 3600))))
    }
}

struct NameTagWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKinds.nameTag, provider: NameTagProvider()) { entry in
            NameTagView(tag: entry.tag, accent: entry.settings.accent, fontDesign: entry.settings.font.design)
                .containerBackground(for: .widget) {
                    StudioWidgetBackground(widget: .nameTag, settings: entry.settings)
                }
        }
        .configurationDisplayName("Name Tag")
        .description(StudioWidget.nameTag.summary)
        .standByStyle()
    }
}
