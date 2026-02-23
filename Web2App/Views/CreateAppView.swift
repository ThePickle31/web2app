import SwiftUI

struct CreateAppView: View {
    @Environment(WebAppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultOutputDirectory") private var storedDirectory = ""

    @State private var urlString: String
    @State private var name = ""
    @State private var iconData: Data?
    @State private var iconImage: NSImage?
    @State private var isFetchingFavicon = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var validatedURL: URL?
    @State private var fetchTask: Task<Void, Never>?

    init(initialURL: URL? = nil) {
        _urlString = State(initialValue: initialURL?.absoluteString ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            WebAppFormView(
                urlString: $urlString,
                name: $name,
                iconData: $iconData,
                iconImage: $iconImage,
                isFetchingFavicon: $isFetchingFavicon,
                errorMessage: $errorMessage,
                fetchTask: $fetchTask
            )

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
        .onAppear {
            if !urlString.isEmpty {
                validateAndFetchMetadata()
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
                name = url.host()?.replacingOccurrences(of: "www.", with: "")
                    .components(separatedBy: ".").first?.capitalized ?? "Web App"
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

    private static func defaultOutputDirectory() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            fatalError("Application Support directory not available")
        }
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
        let safeName = BundleStructureBuilder.sanitizeAppName(name)
        let existingApp = outputDirectory.appendingPathComponent("\(safeName).app")
        if FileManager.default.fileExists(atPath: existingApp.path()) {
            do {
                try FileManager.default.removeItem(at: existingApp)
            } catch {
                errorMessage = "Failed to remove existing app: \(error.localizedDescription)"
                return
            }
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
