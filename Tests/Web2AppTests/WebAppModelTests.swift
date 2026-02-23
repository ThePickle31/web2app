import Testing
import Foundation
@testable import Web2App

@Suite("WebApp Model Tests")
struct WebAppModelTests {

    @Test("WebApp initializes with correct defaults")
    func defaultInit() {
        let url = URL(string: "https://example.com")!
        let app = WebApp(name: "Example", url: url)

        #expect(app.name == "Example")
        #expect(app.url == url)
        #expect(app.bundleIdentifier == "com.web2app.example")
        #expect(app.iconData == nil)
        #expect(app.generatedAppPath == nil)
        #expect(app.allowedDomains.isEmpty)
    }

    @Test("WebApp hostname extraction")
    func hostnameExtraction() {
        let url = URL(string: "https://news.ycombinator.com/newest")!
        let app = WebApp(name: "HN", url: url)

        #expect(app.hostname == "news.ycombinator.com")
    }

    @Test("WebApp bundle identifier sanitizes name")
    func bundleIdentifierSanitization() {
        let url = URL(string: "https://example.com")!
        let app = WebApp(name: "My Cool App!", url: url)

        #expect(app.bundleIdentifier == "com.web2app.my-cool-app")
    }

    @Test("WebApp Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let url = URL(string: "https://example.com")!
        let original = WebApp(
            name: "Example",
            url: url,
            bundleIdentifier: "com.test.example",
            iconData: Data([0x89, 0x50, 0x4E, 0x47]),
            allowedDomains: ["cdn.example.com", "api.example.com"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WebApp.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.url == original.url)
        #expect(decoded.bundleIdentifier == original.bundleIdentifier)
        #expect(decoded.iconData == original.iconData)
        #expect(decoded.createdAt == original.createdAt)
        #expect(decoded.allowedDomains == original.allowedDomains)
    }

    @Test("WebApp Hashable conformance")
    func hashableConformance() {
        let url = URL(string: "https://example.com")!
        let app1 = WebApp(name: "Example", url: url)
        let app2 = app1

        #expect(app1 == app2)
        #expect(app1.hashValue == app2.hashValue)
    }

    @Test("WebApp with custom bundle identifier")
    func customBundleIdentifier() {
        let url = URL(string: "https://example.com")!
        let app = WebApp(name: "Example", url: url, bundleIdentifier: "com.custom.id")

        #expect(app.bundleIdentifier == "com.custom.id")
    }
}
