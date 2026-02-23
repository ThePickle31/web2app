import SwiftUI

struct ContentView: View {
    @Environment(WebAppStore.self) private var store
    @State private var selectedAppID: WebApp.ID?
    @State private var isCreateSheetPresented = false

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
        .sheet(isPresented: $isCreateSheetPresented) {
            CreateAppView()
        }
        .onDrop(of: [.url], isTargeted: nil) { providers in
            handleURLDrop(providers)
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
                DispatchQueue.main.async {
                    isCreateSheetPresented = true
                }
            }
        }
        return true
    }
}
