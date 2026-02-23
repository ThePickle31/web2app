import SwiftUI

struct SettingsView: View {
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
        }
        .frame(width: 450, height: 200)
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
