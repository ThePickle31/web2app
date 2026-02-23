import Foundation
import os

struct PlistGenerator {
    private static let logger = Logger(subsystem: "com.web2app", category: "PlistGenerator")

    /// Generates a standard macOS app Info.plist.
    static func generateInfoPlist(name: String, bundleIdentifier: String) throws -> Data {
        let plistDict: [String: Any] = [
            "CFBundleExecutable": "WebAppLauncher",
            "CFBundleName": name,
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleIconFile": "AppIcon",
            "CFBundlePackageType": "APPL",
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
            "LSMinimumSystemVersion": "15.0",
            "NSAppTransportSecurity": [
                "NSAllowsArbitraryLoads": true
            ]
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plistDict,
            format: .xml,
            options: 0
        )

        logger.info("Generated Info.plist for \(name)")
        return data
    }

    /// Generates a custom configuration plist with the web app's URL and settings.
    static func generateConfigPlist(url: URL, name: String, allowedDomains: [String]) throws -> Data {
        let plistDict: [String: Any] = [
            "URL": url.absoluteString,
            "AppName": name,
            "AllowedDomains": allowedDomains
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plistDict,
            format: .xml,
            options: 0
        )

        logger.info("Generated config.plist for \(name)")
        return data
    }
}
