import Foundation
import os

struct BundleStructureBuilder {
    private static let logger = Logger(subsystem: "com.web2app", category: "BundleStructureBuilder")

    /// Creates the .app bundle directory structure at the given base URL.
    /// Returns the URL to the created .app bundle.
    static func build(at baseURL: URL, appName: String) throws -> URL {
        let fileManager = FileManager.default
        let appURL = baseURL.appendingPathComponent("\(appName).app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)

        try fileManager.createDirectory(at: macOSURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

        logger.info("Created bundle structure at \(appURL.path(percentEncoded: false))")
        return appURL
    }
}
