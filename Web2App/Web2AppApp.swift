import SwiftUI

@main
struct Web2AppApp: App {
    @State private var store = WebAppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(store: store)
        }

        Settings {
            SettingsView()
        }
    }
}
