import Testing
import Foundation
@testable import Web2App

@Suite("BundleStructureBuilder Tests")
struct BundleStructureBuilderTests {

    @Test("Creates correct .app bundle structure")
    func createsCorrectStructure() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let appURL = try BundleStructureBuilder.build(at: tempDir, appName: "TestApp")

        #expect(appURL.lastPathComponent == "TestApp.app")

        let fm = FileManager.default
        #expect(fm.fileExists(atPath: appURL.appendingPathComponent("Contents/MacOS").path()))
        #expect(fm.fileExists(atPath: appURL.appendingPathComponent("Contents/Resources").path()))
    }

    @Test("App name with spaces is handled")
    func appNameWithSpaces() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let appURL = try BundleStructureBuilder.build(at: tempDir, appName: "My Test App")

        #expect(appURL.lastPathComponent == "My Test App.app")
    }

    @Test("Returns correct URL path")
    func returnsCorrectPath() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let appURL = try BundleStructureBuilder.build(at: tempDir, appName: "Example")

        #expect(appURL.path().contains("Example.app"))
        #expect(appURL.lastPathComponent == "Example.app")
        // Compare resolved paths to handle /tmp -> /private/tmp symlink
        let parentResolved = appURL.deletingLastPathComponent().resolvingSymlinksInPath().path()
        let tempResolved = tempDir.resolvingSymlinksInPath().path()
        #expect(parentResolved == tempResolved)
    }
}
