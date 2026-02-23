import SwiftUI

struct EmptyStateView: View {
    let onCreate: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Web App Selected", systemImage: "globe")
        } description: {
            Text("Select a web app from the sidebar or create a new one.")
        } actions: {
            Button("Create New Web App") {
                onCreate()
            }
            .buttonStyle(.borderedProminent)
            .glassBackground()
        }
    }
}
