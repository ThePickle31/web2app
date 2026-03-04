import SwiftUI

struct UpdateBannerView: View {
    let currentVersion: String
    let availableVersion: String
    let isBeta: Bool
    let onUpdate: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text("Update Available")
                    .fontWeight(.semibold)
                if isBeta {
                    Text("Beta")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
            .font(.subheadline)

            HStack(spacing: 4) {
                Text(currentVersion)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(availableVersion)
                    .foregroundStyle(.primary)
            }
            .font(.caption)

            HStack(spacing: 8) {
                Button("Update") {
                    onUpdate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
    }
}
