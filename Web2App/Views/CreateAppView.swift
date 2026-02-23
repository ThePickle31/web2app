import SwiftUI

struct CreateAppView: View {
    @Environment(WebAppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var urlString = ""
    @State private var name = ""
    @State private var iconData: Data?
    @State private var iconImage: NSImage?
    @State private var isFetchingFavicon = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var validatedURL: URL?
    @State private var fetchTask: Task<Void, Never>?

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
                    // Auto-fetch favicon after user stops typing
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

                Button("Choose Custom Icon...") {
                    pickCustomIcon()
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

            Button {
                createApp()
            } label: {
                if isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Creating...")
                    }
                } else {
                    Text("Create App")
                }
            }
            .disabled(isGenerating || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.defaultAction)
            .glassBackground()
        }
    }

    // MARK: - Actions

    private func validateAndFetchMetadata() {
        do {
            let url = try URLValidator.validate(urlString)
            validatedURL = url
            errorMessage = nil

            if name.isEmpty {
                name = url.host()?.replacingOccurrences(of: "www.", with: "").components(separatedBy: ".").first?.capitalized ?? "Web App"
            }

            fetchFavicon(for: url)
        } catch {
            errorMessage = error.localizedDescription
            validatedURL = nil
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

    private static func defaultOutputDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Web2App/GeneratedApps", isDirectory: true)
    }

    private func createApp() {
        do {
            let url = try URLValidator.validate(urlString)
            validatedURL = url
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        guard let validatedURL else { return }

        guard let launcherURL = Bundle.main.url(forResource: "WebAppLauncher", withExtension: nil) else {
            errorMessage = "WebAppLauncher binary not found in app bundle."
            return
        }

        @AppStorage("defaultOutputDirectory") var storedDirectory = ""
        let outputDirectory: URL
        if !storedDirectory.isEmpty {
            outputDirectory = URL(fileURLWithPath: storedDirectory)
        } else {
            outputDirectory = Self.defaultOutputDirectory()
        }

        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        } catch {
            errorMessage = "Failed to create output directory: \(error.localizedDescription)"
            return
        }

        // Remove existing app with same name if present
        let existingApp = outputDirectory.appendingPathComponent("\(name).app")
        if FileManager.default.fileExists(atPath: existingApp.path()) {
            try? FileManager.default.removeItem(at: existingApp)
        }

        let webApp = WebApp(
            name: name,
            url: validatedURL,
            iconData: iconData
        )

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let generatedURL = try await AppGenerator.generate(
                    webApp: webApp,
                    outputDirectory: outputDirectory,
                    launcherBinaryURL: launcherURL,
                    iconData: iconData
                )

                var savedApp = webApp
                savedApp.generatedAppPath = generatedURL.path(percentEncoded: false)
                store.add(savedApp)

                isGenerating = false
                dismiss()
            } catch {
                isGenerating = false
                errorMessage = "Generation failed: \(error.localizedDescription)"
            }
        }
    }
}
