import SwiftUI

struct AppCommands: Commands {
    let store: WebAppStore

    var body: some Commands {
        SidebarCommands()

        CommandGroup(replacing: .newItem) {
            Button("New Web App") {
                NotificationCenter.default.post(name: .createNewWebApp, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Import URL from Clipboard") {
                NotificationCenter.default.post(name: .importURLFromClipboard, object: nil)
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        }

        CommandMenu("Web App") {
            Button("Edit Selected") {
                NotificationCenter.default.post(name: .editSelectedApp, object: nil)
            }
            .keyboardShortcut("e", modifiers: .command)

            Button("Reveal in Finder") {
                NotificationCenter.default.post(name: .revealSelectedAppInFinder, object: nil)
            }

            Button("Open Generated App") {
                NotificationCenter.default.post(name: .openSelectedGeneratedApp, object: nil)
            }

            Divider()

            Button("Delete Selected") {
                NotificationCenter.default.post(name: .deleteSelectedApp, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }
    }
}

extension Notification.Name {
    static let createNewWebApp = Notification.Name("createNewWebApp")
    static let importURLFromClipboard = Notification.Name("importURLFromClipboard")
    static let revealSelectedAppInFinder = Notification.Name("revealSelectedAppInFinder")
    static let openSelectedGeneratedApp = Notification.Name("openSelectedGeneratedApp")
    static let editSelectedApp = Notification.Name("editSelectedApp")
    static let deleteSelectedApp = Notification.Name("deleteSelectedApp")
}
