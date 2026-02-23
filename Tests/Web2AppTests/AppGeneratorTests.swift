import Testing
import Foundation
@testable import Web2App

@Suite("AppGenerator Tests")
struct AppGeneratorTests {

    @Test("Generated app has correct directory structure")
    func generatedAppStructure() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create a fake launcher binary
        let fakeLauncher = tempDir.appendingPathComponent("FakeLauncher")
        try Data("#!/bin/sh\necho hello".utf8).write(to: fakeLauncher)

        let webApp = WebApp(
            name: "TestApp",
            url: URL(string: "https://example.com")!,
            allowedDomains: ["cdn.example.com"]
        )

        let outputDir = tempDir.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let appURL = try await AppGenerator.generate(
            webApp: webApp,
            outputDirectory: outputDir,
            launcherBinaryURL: fakeLauncher,
            iconData: nil
        )

        let fm = FileManager.default
        #expect(fm.fileExists(atPath: appURL.appendingPathComponent("Contents/Info.plist").path()))
        #expect(fm.fileExists(atPath: appURL.appendingPathComponent("Contents/MacOS/WebAppLauncher").path()))
        #expect(fm.fileExists(atPath: appURL.appendingPathComponent("Contents/Resources/config.plist").path()))
    }

    @Test("Generated Info.plist has correct bundle identifier")
    func generatedInfoPlist() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeLauncher = tempDir.appendingPathComponent("FakeLauncher")
        try Data("#!/bin/sh".utf8).write(to: fakeLauncher)

        let webApp = WebApp(
            name: "TestApp",
            url: URL(string: "https://example.com")!,
            bundleIdentifier: "com.test.myapp"
        )

        let outputDir = tempDir.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let appURL = try await AppGenerator.generate(
            webApp: webApp,
            outputDirectory: outputDir,
            launcherBinaryURL: fakeLauncher,
            iconData: nil
        )

        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        let plistData = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as! [String: Any]

        #expect(plist["CFBundleIdentifier"] as? String == "com.test.myapp")
        #expect(plist["CFBundleName"] as? String == "TestApp")
    }

    @Test("Generated config.plist has correct URL")
    func generatedConfigPlist() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeLauncher = tempDir.appendingPathComponent("FakeLauncher")
        try Data("#!/bin/sh".utf8).write(to: fakeLauncher)

        let webApp = WebApp(
            name: "TestApp",
            url: URL(string: "https://news.ycombinator.com")!,
            allowedDomains: ["cdn.ycombinator.com"]
        )

        let outputDir = tempDir.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let appURL = try await AppGenerator.generate(
            webApp: webApp,
            outputDirectory: outputDir,
            launcherBinaryURL: fakeLauncher,
            iconData: nil
        )

        let configURL = appURL.appendingPathComponent("Contents/Resources/config.plist")
        let configData = try Data(contentsOf: configURL)
        let config = try PropertyListSerialization.propertyList(from: configData, format: nil) as! [String: Any]

        #expect(config["URL"] as? String == "https://news.ycombinator.com")
        #expect(config["AppName"] as? String == "TestApp")
        #expect(config["AllowedDomains"] as? [String] == ["cdn.ycombinator.com"])
    }
}
