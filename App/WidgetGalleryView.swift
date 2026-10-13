import SwiftUI

struct WidgetGalleryView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var model: SettingsModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(StudioWidget.allCases) { widget in
                    let isLocked = !store.isUnlocked(widget.pack)
                    VStack(alignment: .leading, spacing: 8) {
                        TimelineView(.everyMinute) { context in
                            StudioWidgetTile(widget: widget, date: context.date, settings: model.settings, photo: model.photo)
                        }
                        .overlay(alignment: .topTrailing) {
                            if isLocked { LockBadge() }
                        }
                        Text(widget.title)
                            .font(.subheadline.weight(.semibold))
                        Text(widget.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        PackBadge(pack: widget.pack)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Widgets")
        .toolbar { CustomizeButton() }
    }
}
