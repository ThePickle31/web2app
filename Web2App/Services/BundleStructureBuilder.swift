import Foundation
import os

struct BundleStructureBuilder {
    private static let logger = Logger(subsystem: "com.web2app", category: "BundleStructureBuilder")

    /// Strips path separators and dangerous characters from an app name
    /// to prevent path traversal when constructing file paths.
    static func sanitizeAppName(_ name: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\:\u{0000}")
        let sanitized = name.components(separatedBy: forbidden).joined()
        let trimmed = sanitized.replacingOccurrences(of: "..", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "WebApp" : trimmed
    }

    /// Creates the .app bundle directory structure at the given base URL.
    /// Returns the URL to the created .app bundle.
    static func build(at baseURL: URL, appName: String) throws -> URL {
        let fileManager = FileManager.default
        let safeName = sanitizeAppName(appName)
        let appURL = baseURL.appendingPathComponent("\(safeName).app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)

        try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

        logger.info("Created bundle structure at \(appURL.path(percentEncoded: false))")
        return appURL
    }
}
