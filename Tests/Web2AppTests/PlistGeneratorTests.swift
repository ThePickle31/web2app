import Testing
import Foundation
@testable import Web2App

@Suite("PlistGenerator Tests")
struct PlistGeneratorTests {

    @Test("Info.plist contains required keys")
    func infoPlistRequiredKeys() throws {
        let data = try PlistGenerator.generateInfoPlist(
            name: "TestApp",
            bundleIdentifier: "com.test.app"
        )

        let raw = try PropertyListSerialization.propertyList(from: data, format: nil)
        let plist = try #require(raw as? [String: Any])

        #expect(plist["CFBundleExecutable"] as? String == "WebAppLauncher")
        #expect(plist["CFBundleName"] as? String == "TestApp")
        #expect(plist["CFBundleIdentifier"] as? String == "com.test.app")
        #expect(plist["CFBundleIconFile"] as? String == "AppIcon")
        #expect(plist["CFBundlePackageType"] as? String == "APPL")
        #expect(plist["LSMinimumSystemVersion"] as? String == "15.0")
    }

    @Test("Info.plist allows arbitrary loads for HTTP support")
    func infoPlistAllowsArbitraryLoads() throws {
        let data = try PlistGenerator.generateInfoPlist(
            name: "TestApp",
            bundleIdentifier: "com.test.app"
        )

        let raw = try PropertyListSerialization.propertyList(from: data, format: nil)
        let plist = try #require(raw as? [String: Any])
        let ats = plist["NSAppTransportSecurity"] as? [String: Any]

        #expect(ats?["NSAllowsArbitraryLoads"] as? Bool == true)
    }

    @Test("Config plist contains URL and app name")
    func configPlistContents() throws {
        let url = URL(string: "https://example.com")!
        let data = try PlistGenerator.generateConfigPlist(
            url: url,
            name: "Example",
            allowedDomains: ["cdn.example.com"]
        )

        let raw = try PropertyListSerialization.propertyList(from: data, format: nil)
        let plist = try #require(raw as? [String: Any])

        #expect(plist["URL"] as? String == "https://example.com")
        #expect(plist["AppName"] as? String == "Example")
        #expect(plist["AllowedDomains"] as? [String] == ["cdn.example.com"])
    }

    @Test("Config plist with empty allowed domains")
    func configPlistEmptyDomains() throws {
        let url = URL(string: "https://example.com")!
        let data = try PlistGenerator.generateConfigPlist(
            url: url,
            name: "Example",
            allowedDomains: []
        )

        let raw = try PropertyListSerialization.propertyList(from: data, format: nil)
        let plist = try #require(raw as? [String: Any])

        #expect((plist["AllowedDomains"] as? [String])?.isEmpty == true)
    }
}
