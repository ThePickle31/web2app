import SwiftUI

struct SettingsView: View {
    @Environment(AppUpdater.self) private var updater

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AdvancedSettingsTab()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }

            UpdatesSettingsTab(updater: updater)
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .frame(width: 450, height: 250)
    }
}

// MARK: - General Settings

private struct GeneralSettingsTab: View {
    @AppStorage("defaultOutputDirectory") private var defaultOutputDirectory = ""
    @AppStorage("autoCodeSign") private var autoCodeSign = true

    var body: some View {
        Form {
            HStack {
                TextField("Default Output Directory", text: $defaultOutputDirectory)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)

                Button("Choose...") {
                    pickOutputDirectory()
                }
            }

            Toggle("Automatically code-sign generated apps", isOn: $autoCodeSign)
        }
        .formStyle(.grouped)
    }

    private func pickOutputDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose Default Output Directory"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            defaultOutputDirectory = url.path(percentEncoded: false)
        }
    }
}

// MARK: - Advanced Settings

private struct AdvancedSettingsTab: View {
    @AppStorage("customUserAgent") private var customUserAgent = ""

    var body: some View {
        Form {
            TextField("Custom User Agent", text: $customUserAgent, prompt: Text("Leave blank for default"))
                .textFieldStyle(.roundedBorder)
        }
        .formStyle(.grouped)
    }
}

// MARK: - Updates Settings

private struct UpdatesSettingsTab: View {
    @Bindable var updater: AppUpdater
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true

    var body: some View {
        Form {
            LabeledContent("Current Version") {
                Text(updater.currentVersion)
                    .foregroundStyle(.secondary)
            }

            statusView

            HStack {
                actionButton

                if case .downloading = updater.status {
                    Button("Cancel") {
                        updater.cancelUpdate()
                    }
                }
            }

            Toggle("Automatically check for updates", isOn: $autoCheckForUpdates)
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var statusView: some View {
        switch updater.status {
        case .idle:
            EmptyView()
        case .checking:
            LabeledContent("Status") {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking for updates...")
                        .foregroundStyle(.secondary)
                }
            }
        case .upToDate:
            LabeledContent("Status") {
                Text("Web2App is up to date")
                    .foregroundStyle(.secondary)
            }
        case .updateAvailable(let version):
            LabeledContent("Status") {
                Text("Version \(version) is available")
                    .foregroundStyle(.orange)
            }
        case .downloading(let progress):
            LabeledContent("Status") {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Downloading... \(Int(progress * 100))%")
                        .foregroundStyle(.secondary)
                    ProgressView(value: progress)
                        .frame(width: 150)
                }
            }
        case .installing:
            LabeledContent("Status") {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Installing update...")
                        .foregroundStyle(.secondary)
                }
            }
        case .error(let message):
            LabeledContent("Status") {
                Text(message)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch updater.status {
        case .updateAvailable:
            Button("Download & Install") {
                updater.downloadAndInstall()
            }
        case .downloading, .installing:
            EmptyView()
        case .error:
            Button("Retry") {
                updater.checkForUpdates()
            }
        default:
            Button("Check for Updates") {
                updater.checkForUpdates()
            }
            .disabled(updater.status == .checking)
        }
    }
}
