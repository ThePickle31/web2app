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
            WebAppFormView(
                urlString: $urlString,
                name: $name,
                iconData: $iconData,
                iconImage: $iconImage,
                isFetchingFavicon: $isFetchingFavicon,
                errorMessage: $errorMessage,
                showRefetchButton: true,
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
