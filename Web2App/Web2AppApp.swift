import SwiftUI

@main
struct Web2AppApp: App {
    @State private var store = WebAppStore()
    @State private var updater = AppUpdater()
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(updater)
                .task {
                    if autoCheckForUpdates {
                        try? await Task.sleep(for: .seconds(3))
                        updater.checkForUpdates()
                    }
                }
        }
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(store: store, updater: updater)
        }

        Settings {
            SettingsView()
                .environment(updater)
        }
    }
}
