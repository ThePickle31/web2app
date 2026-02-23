import AppKit
import Foundation

struct WebApp: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var url: URL
    var bundleIdentifier: String
    var iconData: Data?
    var createdAt: Date
    var generatedAppPath: String?
    var allowedDomains: [String]

    init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        bundleIdentifier: String? = nil,
        iconData: Data? = nil,
        createdAt: Date = Date(),
        generatedAppPath: String? = nil,
        allowedDomains: [String] = []
    ) {
        self.id = id
        self.name = name
        self.url = url
        let sanitized = name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let suffix = sanitized.isEmpty ? UUID().uuidString.prefix(8).lowercased() : sanitized
        let truncated = String(suffix.prefix(50))
        self.bundleIdentifier = bundleIdentifier ?? "com.web2app.\(truncated)"
        self.iconData = iconData
        self.createdAt = createdAt
        self.generatedAppPath = generatedAppPath
        self.allowedDomains = allowedDomains
    }

    var hostname: String {
        url.host() ?? url.absoluteString
    }

    var iconImage: NSImage? {
        guard let data = iconData else { return nil }
        return NSImage(data: data)
    }
}
