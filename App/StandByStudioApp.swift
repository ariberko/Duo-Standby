import SwiftUI

@main
struct StandByStudioApp: App {
    @StateObject private var store = Store()
    @StateObject private var model = SettingsModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(model)
                .preferredColorScheme(.dark)
        }
    }
}
