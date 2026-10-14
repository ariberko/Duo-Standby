import SwiftUI

@main
struct PreviewApp: App {
    var body: some Scene {
        WindowGroup {
            PreviewGallery()
                .preferredColorScheme(.dark)
        }
    }
}

enum PreviewItem: Identifiable, Hashable {
    case clock(ClockStyle)
    case widget(StudioWidget)

    var id: String {
        switch self {
        case .clock(let style): "clock-\(style.rawValue)"
        case .widget(let widget): "widget-\(widget.rawValue)"
        }
    }
}

struct PreviewGallery: View {
    @State private var settings = StudioSettings.load()
    @State private var showing: PreviewItem?
    @State private var showingSettings = false
    @State private var showingNameTag = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Tap any design to see it full screen, like StandBy. Turn the iPad sideways for two side by side.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        LiveGalleryView()
                    } label: {
                        Label("Live scenes: DVD Bounce, Matrix, Fireplace and more", systemImage: "play.tv")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    ForEach(Pack.allCases.filter { pack in
                        !ClockStyle.styles(in: pack).isEmpty || StudioWidget.allCases.contains { $0.pack == pack }
                    }) { pack in
                        VStack(alignment: .leading, spacing: 12) {
                            PackBadge(pack: pack)
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(ClockStyle.styles(in: pack)) { style in
                                    cell(.clock(style), title: style.title)
                                }
                                ForEach(StudioWidget.allCases.filter { $0.pack == pack }) { widget in
                                    cell(.widget(widget), title: widget.title)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Duo StandBy")
            .toolbar {
                Button {
                    showingNameTag = true
                } label: {
                    Label("Name Tag", systemImage: "person.text.rectangle")
                }
                Button {
                    showingSettings = true
                } label: {
                    Label("Customize", systemImage: "paintpalette")
                }
            }
        }
        .sheet(isPresented: $showingNameTag) {
            NavigationStack {
                NameTagEditorView(accent: settings.accent, fontDesign: settings.font.design)
            }
        }
        .sheet(isPresented: $showingSettings) {
            PreviewSettingsView(settings: $settings)
        }
        .fullScreenCover(item: $showing) { item in
            StandByMock(item: item, settings: settings)
        }
        .onChange(of: settings) { _, newValue in
            newValue.save()
        }
    }

    private func cell(_ item: PreviewItem, title: String) -> some View {
        Button {
            showing = item
        } label: {
            VStack(spacing: 8) {
                TimelineView(.everyMinute) { context in
                    tile(item, date: context.date, settings: settings)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .buttonStyle(.plain)
    }
}

@ViewBuilder
func tile(_ item: PreviewItem, date: Date, settings: StudioSettings) -> some View {
    switch item {
    case .clock(let style):
        ClockTile(style: style, date: date, settings: settings)
    case .widget(let widget):
        StudioWidgetTile(widget: widget, date: date, settings: settings, photo: nil)
    }
}

/// Full screen black, like StandBy. Two widgets side by side when wide.
struct StandByMock: View {
    let item: PreviewItem
    let settings: StudioSettings

    @Environment(\.dismiss) private var dismiss

    private var partner: PreviewItem {
        item == .widget(.calendar) ? .clock(.flip) : .widget(.calendar)
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.everyMinute) { context in
                if geo.size.width > geo.size.height {
                    HStack(spacing: 24) {
                        tile(item, date: context.date, settings: settings)
                        tile(partner, date: context.date, settings: settings)
                    }
                } else {
                    tile(item, date: context.date, settings: settings)
                }
            }
            .padding(32)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            Text("Tap to close")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 12)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
}

struct PreviewSettingsView: View {
    @Binding var settings: StudioSettings
    @Environment(\.dismiss) private var dismiss

    private let swatches = ["#FF9F0A", "#FF375F", "#BF5AF2", "#0A84FF", "#64D2FF", "#30D158", "#FFD60A", "#FFFFFF"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Accent color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 12) {
                        ForEach(swatches, id: \.self) { hex in
                            Button {
                                settings.accentHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if settings.accentHex == hex {
                                            Circle().stroke(Color.white, lineWidth: 3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ColorPicker("Custom color", selection: Binding(
                        get: { settings.accent },
                        set: { settings.accentHex = $0.hexString }
                    ), supportsOpacity: false)
                }
                Section("Clock") {
                    Toggle("24-hour time", isOn: $settings.use24Hour)
                    Picker("Font", selection: $settings.font) {
                        ForEach(FontChoice.allCases) { font in
                            Text(font.title).tag(font)
                        }
                    }
                }
                Section("Countdown") {
                    TextField("Title", text: $settings.countdownTitle)
                    DatePicker("Date", selection: $settings.countdownDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Customize")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
