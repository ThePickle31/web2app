import SwiftUI

struct DetailView: View {
    @Environment(WebAppStore.self) private var store
    @Binding var webApp: WebApp
    @Binding var selection: WebApp.ID?
    @State private var isEditSheetPresented = false
    @State private var isDeleteConfirmPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            iconView
                .frame(width: 128, height: 128)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            VStack(spacing: 6) {
                Text(webApp.name)
                    .font(.title)
                    .fontWeight(.bold)

                Link(webApp.hostname, destination: webApp.url)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if webApp.generatedAppPath != nil {
                    Button {
                        openGeneratedApp()
                    } label: {
                        Label("Open App", systemImage: "arrow.up.forward.app")
                    }
                    .controlSize(.large)
                    .glassBackground()

                    Button {
                        revealInFinder()
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                    .controlSize(.large)
                    .glassBackground()
                }

                Button {
                    isEditSheetPresented = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .controlSize(.large)
                .glassBackground()

                Button(role: .destructive) {
                    isDeleteConfirmPresented = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .controlSize(.large)
                .glassBackground()
            }

            if let path = webApp.generatedAppPath {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 400)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $isEditSheetPresented) {
            EditAppView(webApp: webApp)
        }
        .alert("Delete \(webApp.name)?", isPresented: $isDeleteConfirmPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.delete(webApp)
                selection = nil
            }
        } message: {
            Text("This will also remove the generated app if one exists. This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconImage = webApp.iconImage {
            Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.quaternary)
                Image(systemName: "globe")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func openGeneratedApp() {
        guard let path = webApp.generatedAppPath else { return }
        let appURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(appURL)
    }

    private func revealInFinder() {
        guard let path = webApp.generatedAppPath else { return }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
