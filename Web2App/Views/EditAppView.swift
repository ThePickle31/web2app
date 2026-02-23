import SwiftUI

struct EditAppView: View {
    @Environment(WebAppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let webApp: WebApp

    @State private var urlString: String
    @State private var name: String
    @State private var iconData: Data?
    @State private var iconImage: NSImage?
    @State private var isFetchingFavicon = false
    @State private var errorMessage: String?
    @State private var fetchTask: Task<Void, Never>?

    init(webApp: WebApp) {
        self.webApp = webApp
        _urlString = State(initialValue: webApp.url.absoluteString)
        _name = State(initialValue: webApp.name)
        _iconData = State(initialValue: webApp.iconData)
        _iconImage = State(initialValue: webApp.iconImage)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                urlSection
                nameSection
                iconSection
            }
            .formStyle(.grouped)
            .padding(.bottom, 0)

            if let errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            actionButtons
                .padding()
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 500, idealHeight: 560)
    }

    // MARK: - URL Section

    private var urlSection: some View {
        Section("URL") {
            TextField("https://example.com", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    validateAndFetchMetadata()
                }
                .onChange(of: urlString) {
                    errorMessage = nil
                    fetchTask?.cancel()
                    fetchTask = Task {
                        try? await Task.sleep(for: .milliseconds(800))
                        guard !Task.isCancelled else { return }
                        validateAndFetchMetadata()
                    }
                }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        Section("App Name") {
            TextField("My Web App", text: $name)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        Section("Icon") {
            VStack(spacing: 12) {
                iconPreview
                    .frame(width: 128, height: 128)
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
                    .frame(maxWidth: .infinity)

                if isFetchingFavicon {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Fetching icon...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if iconImage != nil {
                    Text("Icon loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Button("Choose Custom Icon...") {
                        pickCustomIcon()
                    }

                    Button("Re-fetch from URL") {
                        if let url = try? URLValidator.validate(urlString) {
                            fetchFavicon(for: url)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var iconPreview: some View {
        if let iconImage {
            Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack {
            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])

            Button("Save") {
                saveChanges()
            }
            .disabled(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.defaultAction)
            .glassBackground()
        }
    }

    // MARK: - Actions

    private func validateAndFetchMetadata() {
        do {
            let url = try URLValidator.validate(urlString)
            errorMessage = nil

            if iconData == nil || urlString != webApp.url.absoluteString {
                fetchFavicon(for: url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchFavicon(for url: URL) {
        isFetchingFavicon = true
        let fetcher = FaviconFetcher()

        Task {
            let data = await fetcher.fetch(for: url)
            isFetchingFavicon = false

            if let data, let image = NSImage(data: data) {
                iconData = data
                iconImage = image
            }
        }
    }

    private func pickCustomIcon() {
        let panel = NSOpenPanel()
        panel.title = "Choose an Icon Image"
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .icns]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let selectedURL = panel.url else { return }

        do {
            let data = try Data(contentsOf: selectedURL)
            guard let image = NSImage(data: data) else {
                errorMessage = "Could not read the selected image file."
                return
            }
            iconData = data
            iconImage = image
        } catch {
            errorMessage = "Failed to read image: \(error.localizedDescription)"
        }
    }

    private func saveChanges() {
        do {
            let url = try URLValidator.validate(urlString)
            errorMessage = nil

            var updated = webApp
            updated.name = name
            updated.url = url
            updated.iconData = iconData
            store.update(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
