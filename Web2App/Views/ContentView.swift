import SwiftUI

struct ContentView: View {
    @Environment(WebAppStore.self) private var store
    @State private var selectedAppID: WebApp.ID?
    @State private var isCreateSheetPresented = false
    @State private var droppedURL: URL?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedAppID)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isCreateSheetPresented = true
                        } label: {
                            Label("New Web App", systemImage: "plus")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        .help("Create a new web app (Cmd+N)")
                    }
                }
        } detail: {
            if let selectedAppID, store.apps.contains(where: { $0.id == selectedAppID }) {
                DetailView(webApp: bindingForApp(id: selectedAppID), selection: $selectedAppID)
            } else {
                EmptyStateView {
                    isCreateSheetPresented = true
                }
            }
        }
        .sheet(isPresented: $isCreateSheetPresented, onDismiss: { droppedURL = nil }) {
            CreateAppView(initialURL: droppedURL)
        }
        .onDrop(of: [.url], isTargeted: nil) { providers in
            handleURLDrop(providers)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewWebApp)) { _ in
            isCreateSheetPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .importURLFromClipboard)) { _ in
            importFromClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: .editSelectedApp)) { _ in
            // Handled by SidebarView/DetailView which own the edit sheet
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelectedApp)) { _ in
            if let selectedAppID, let app = store.apps.first(where: { $0.id == selectedAppID }) {
                store.delete(app)
                self.selectedAppID = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .revealSelectedAppInFinder)) { _ in
            if let selectedAppID,
               let app = store.apps.first(where: { $0.id == selectedAppID }),
               let path = app.generatedAppPath {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSelectedGeneratedApp)) { _ in
            if let selectedAppID,
               let app = store.apps.first(where: { $0.id == selectedAppID }),
               let path = app.generatedAppPath {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }
        }
    }

    private func bindingForApp(id: WebApp.ID) -> Binding<WebApp> {
        Binding(
            get: {
                store.apps.first(where: { $0.id == id })
                    ?? WebApp(name: "", url: URL(string: "https://example.com")!)
            },
            set: { store.update($0) }
        )
    }

    private func handleURLDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in
                    droppedURL = url
                    isCreateSheetPresented = true
                }
            }
        }
        return true
    }

    private func importFromClipboard() {
        guard let string = NSPasteboard.general.string(forType: .string),
              let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return
        }
        droppedURL = url
        isCreateSheetPresented = true
    }
}
