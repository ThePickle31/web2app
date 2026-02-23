import Testing
import Foundation
@testable import Web2App

@Suite("BundleStructureBuilder Sanitization Tests")
struct BundleStructureSanitizationTests {

    @Test("Normal name passes through unchanged")
    func normalName() {
        #expect(BundleStructureBuilder.sanitizeAppName("My App") == "My App")
    }

    @Test("Path traversal characters are stripped")
    func pathTraversal() {
        #expect(BundleStructureBuilder.sanitizeAppName("../../Evil") == "Evil")
        #expect(BundleStructureBuilder.sanitizeAppName("test/../../../etc") == "testetc")
    }

    @Test("Forward slashes are stripped")
    func forwardSlashes() {
        #expect(BundleStructureBuilder.sanitizeAppName("test/app") == "testapp")
    }

    @Test("Backslashes are stripped")
    func backslashes() {
        #expect(BundleStructureBuilder.sanitizeAppName("test\\app") == "testapp")
    }

    @Test("Empty name returns fallback")
    func emptyName() {
        #expect(BundleStructureBuilder.sanitizeAppName("") == "WebApp")
    }

    @Test("Whitespace-only name returns fallback")
    func whitespaceOnly() {
        #expect(BundleStructureBuilder.sanitizeAppName("   ") == "WebApp")
    }

    @Test("Null bytes are stripped")
    func nullBytes() {
        #expect(BundleStructureBuilder.sanitizeAppName("test\0app") == "testapp")
    }

    @Test("Name with only dangerous characters returns fallback")
    func onlyDangerousChars() {
        #expect(BundleStructureBuilder.sanitizeAppName("/../..") == "WebApp")
    }
}
