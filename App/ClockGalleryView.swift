import SwiftUI

struct ClockGalleryView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var model: SettingsModel

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HowToCard()
                ForEach(Pack.allCases) { pack in
                    let styles = ClockStyle.styles(in: pack)
                    if !styles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                PackBadge(pack: pack)
                                Spacer()
                                if !store.isUnlocked(pack) {
                                    Text("Locked").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(styles) { style in
                                    NavigationLink(value: style) {
                                        ClockCell(style: style, isLocked: !store.isUnlocked(pack), settings: model.settings)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Duo StandBy")
        .toolbar { CustomizeButton() }
        .navigationDestination(for: ClockStyle.self) { style in
            StyleDetailView(style: style)
        }
    }
}

struct ClockCell: View {
    let style: ClockStyle
    let isLocked: Bool
    let settings: StudioSettings

    var body: some View {
        VStack(spacing: 8) {
            TimelineView(.everyMinute) { context in
                ClockTile(style: style, date: context.date, settings: settings)
            }
            .overlay(alignment: .topTrailing) {
                if isLocked { LockBadge() }
            }
            Text(style.title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

struct HowToCard: View {
    @AppStorage("howToCollapsed") private var collapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { collapsed.toggle() }
            } label: {
                HStack {
                    Label("How to use StandBy", systemImage: "info.circle")
                        .font(.headline)
                    Spacer()
                    Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                }
            }
            .buttonStyle(.plain)
            if !collapsed {
                VStack(alignment: .leading, spacing: 6) {
                    step(1, "Charge your iPhone, turn it sideways and let it rest.")
                    step(2, "Swipe to the widgets screen. Long-press a widget stack.")
                    step(3, "Tap +, search \"Duo StandBy\". Every clock style is its own widget.")
                    step(4, "Same on the Home Screen and Lock Screen: long-press, Edit, Add Widget.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.3), in: Circle())
            Text(text)
        }
    }
}
