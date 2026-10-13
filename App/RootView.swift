import SwiftUI

enum AppTab: Hashable {
    case clocks, widgets, customize, store
}

struct RootView: View {
    @State private var tab: AppTab = .clocks

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { ClockGalleryView() }
                .tabItem { Label("Clocks", systemImage: "clock") }
                .tag(AppTab.clocks)
            NavigationStack { WidgetGalleryView() }
                .tabItem { Label("Widgets", systemImage: "square.grid.2x2") }
                .tag(AppTab.widgets)
            NavigationStack { CustomizeView() }
                .tabItem { Label("Customize", systemImage: "paintpalette") }
                .tag(AppTab.customize)
            NavigationStack { StoreView() }
                .tabItem { Label("Store", systemImage: "crown") }
                .tag(AppTab.store)
        }
        .onOpenURL { url in
            if url.host == "store" { tab = .store }
        }
    }
}
