import SwiftUI

struct SidebarView: View {
    @Environment(WebAppStore.self) private var store
    @Binding var selection: WebApp.ID?
    @State private var editingApp: WebApp?

    var body: some View {
        List(selection: $selection) {
            ForEach(store.apps) { app in
                WebAppRow(webApp: app)
                    .tag(app.id)
                    .contextMenu {
                        contextMenu(for: app)
                    }
            }
            .onDelete { offsets in
                store.delete(at: offsets)
                if let selection, !store.apps.contains(where: { $0.id == selection }) {
                    self.selection = nil
                }
            }
            .onMove { source, destination in
                store.move(from: source, to: destination)
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if store.apps.isEmpty {
                Text("No Web Apps")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $editingApp) { app in
            EditAppView(webApp: app)
        }
    }

    @ViewBuilder
    private func contextMenu(for app: WebApp) -> some View {
        if let path = app.generatedAppPath {
            Button("Open App") {
                let appURL = URL(fileURLWithPath: path)
                NSWorkspace.shared.open(appURL)
            }

            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
            }
        }

        Button("Edit App...") {
            editingApp = app
        }

        Divider()

        Button("Delete", role: .destructive) {
            store.delete(app)
            if selection == app.id {
                selection = nil
            }
        }
    }

}
