import SwiftUI

struct WebAppFormView: View {
    @Binding var urlString: String
    @Binding var name: String
    @Binding var iconData: Data?
    @Binding var iconImage: NSImage?
    @Binding var isFetchingFavicon: Bool
    @Binding var errorMessage: String?

    var showRefetchButton: Bool = false
    var fetchTask: Binding<Task<Void, Never>?>

    var body: some View {
        Form {
            urlSection
            nameSection
            iconSection
        }
        .formStyle(.grouped)
        .padding(.bottom, 0)
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
                    fetchTask.wrappedValue?.cancel()
                    fetchTask.wrappedValue = Task {
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

                    if showRefetchButton {
                        Button("Re-fetch from URL") {
                            if let url = try? URLValidator.validate(urlString) {
                                fetchFavicon(for: url)
                            }
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

    // MARK: - Actions

    func validateAndFetchMetadata() {
        do {
            let url = try URLValidator.validate(urlString)
            errorMessage = nil

            if name.isEmpty {
                name = url.host()?.replacingOccurrences(of: "www.", with: "")
                    .components(separatedBy: ".").first?.capitalized ?? "Web App"
            }

            if iconData == nil {
                fetchFavicon(for: url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchFavicon(for url: URL) {
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
}
