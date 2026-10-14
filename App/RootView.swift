import SwiftUI
import WidgetKit

enum AppTab: String, Hashable {
    case clocks, widgets, nameTag, live, store
}

/// Launch arguments used by the screenshot workflow on the simulator.
enum ScreenshotMode {
    static var startTab: AppTab? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshotTab"), i + 1 < args.count else { return nil }
        return AppTab(rawValue: args[i + 1])
    }

    /// Shows list prices in the store when the simulator can't reach the App Store.
    static var showsListPrices: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotPrices")
    }
}

struct RootView: View {
    @State private var tab: AppTab = ScreenshotMode.startTab ?? .clocks

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { ClockGalleryView() }
                .tabItem { Label("Clocks", systemImage: "clock") }
                .tag(AppTab.clocks)
            NavigationStack { WidgetGalleryView() }
                .tabItem { Label("Widgets", systemImage: "square.grid.2x2") }
                .tag(AppTab.widgets)
            NavigationStack { NameTagTab() }
                .tabItem { Label("Name Tag", systemImage: "person.text.rectangle") }
                .tag(AppTab.nameTag)
            NavigationStack { LiveTab() }
                .tabItem { Label("Live", systemImage: "play.tv") }
                .tag(AppTab.live)
            NavigationStack { StoreView() }
                .tabItem { Label("Store", systemImage: "crown") }
                .tag(AppTab.store)
        }
        .onOpenURL { url in
            if url.host == "store" { tab = .store }
        }
    }
}

struct NameTagTab: View {
    @EnvironmentObject private var model: SettingsModel

    var body: some View {
        NameTagEditorView(accent: model.settings.accent, fontDesign: model.settings.font.design) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.nameTag)
        }
    }
}

struct LiveTab: View {
    @EnvironmentObject private var store: Store
    @State private var showingStore = false

    var body: some View {
        LiveGalleryView(isUnlocked: { store.isUnlocked($0) }, onLocked: { _ in showingStore = true })
            .sheet(isPresented: $showingStore) {
                NavigationStack { StoreView() }
            }
    }
}

/// Gear button that opens Customize as a sheet.
struct CustomizeButton: View {
    @State private var showing = false

    var body: some View {
        Button {
            showing = true
        } label: {
            Label("Customize", systemImage: "paintpalette")
        }
        .sheet(isPresented: $showing) {
            NavigationStack {
                CustomizeView()
                    .toolbar {
                        Button("Done") { showing = false }
                    }
            }
        }
    }
}
