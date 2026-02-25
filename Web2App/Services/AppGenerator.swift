import AppKit
import Darwin
import Foundation
import os

struct AppGenerator {

    /// Recursively removes the com.apple.quarantine extended attribute
    /// using the C-level removexattr() syscall, which works inside the sandbox container.
    static func removeQuarantine(at url: URL) {
        let path = url.path(percentEncoded: false)
        removexattr(path, "com.apple.quarantine", XATTR_NOFOLLOW)

        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else { return }
        for case let fileURL as URL in enumerator {
            let filePath = fileURL.path(percentEncoded: false)
            removexattr(filePath, "com.apple.quarantine", XATTR_NOFOLLOW)
        }
    }

    /// Removes quarantine via xattr command-line tool, which works for paths
    /// outside the sandbox container (e.g. /Applications) where the C-level
    /// removexattr() syscall may be blocked.
    static func removeQuarantineViaProcess(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-dr", "com.apple.quarantine", url.path(percentEncoded: false)]
        try? process.run()
        process.waitUntilExit()
    }
    private static let logger = Logger(subsystem: "com.web2app", category: "AppGenerator")

    /// Generates a complete .app bundle for the given web app configuration.
    ///
    /// - Parameters:
    ///   - webApp: The web app model containing name, URL, bundle identifier, and allowed domains.
    ///   - outputDirectory: The directory where the .app bundle will be created.
    ///   - launcherBinaryURL: The URL to the pre-built WebAppLauncher binary.
    ///   - iconData: Optional raw image data to use for the app icon.
    /// - Returns: The URL to the created .app bundle.
    static func generate(
        webApp: WebApp,
        outputDirectory: URL,
        launcherBinaryURL: URL,
        iconData: Data?
    ) async throws -> URL {
        let fileManager = FileManager.default

        // Step 0: Remove any existing .app with the same name
        let safeName = BundleStructureBuilder.sanitizeAppName(webApp.name)
        let existingAppURL = outputDirectory.appendingPathComponent("\(safeName).app")
        if fileManager.fileExists(atPath: existingAppURL.path(percentEncoded: false)) {
            try fileManager.removeItem(at: existingAppURL)
            logger.info("Removed existing \(webApp.name).app")
        }

        // Step 1: Create the bundle directory structure
        let appURL = try BundleStructureBuilder.build(at: outputDirectory, appName: webApp.name)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)
        let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)

        logger.info("Building \(webApp.name).app at \(appURL.path(percentEncoded: false))")

        // Step 2: Copy the launcher binary to Contents/MacOS/WebAppLauncher
        let executableURL = macOSURL.appendingPathComponent("WebAppLauncher")
        try fileManager.copyItem(at: launcherBinaryURL, to: executableURL)

        // Step 3: Set executable permissions on the binary
        try fileManager.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: executableURL.path(percentEncoded: false)
        )

        // Step 4: Generate and write Info.plist
        let infoPlistData = try PlistGenerator.generateInfoPlist(
            name: webApp.name,
            bundleIdentifier: webApp.bundleIdentifier
        )
        let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
        try infoPlistData.write(to: infoPlistURL)

        // Step 5: Generate and write config.plist
        let configPlistData = try PlistGenerator.generateConfigPlist(
            url: webApp.url,
            name: webApp.name,
            allowedDomains: webApp.allowedDomains
        )
        let configPlistURL = resourcesURL.appendingPathComponent("config.plist")
        try configPlistData.write(to: configPlistURL)

        // Step 6: Generate and write .icns if icon data is provided
        if let iconData, let image = NSImage(data: iconData) {
            let icnsData = try await IconGenerator.generateICNS(from: image)
            let icnsURL = resourcesURL.appendingPathComponent("AppIcon.icns")
            try icnsData.write(to: icnsURL)
            logger.info("Wrote AppIcon.icns to bundle")
        }

        // Step 7: Code sign the bundle
        try await CodeSigner.sign(appURL: appURL)

        // Step 8: Verify signature before removing quarantine
        try await CodeSigner.verify(appURL: appURL)

        // Step 9: Remove quarantine attribute so macOS doesn't block the app
        removeQuarantine(at: appURL)

        // Step 10: Return the .app URL
        logger.info("Successfully generated \(webApp.name).app")
        return appURL
    }
}
