import SwiftUI

struct WebAppRow: View {
    let webApp: WebApp

    var body: some View {
        HStack(spacing: 8) {
            iconView
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(webApp.name)
                    .font(.body)
                    .lineLimit(1)

                Text(webApp.hostname)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconImage = webApp.iconImage {
            Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "globe")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
    }
}
