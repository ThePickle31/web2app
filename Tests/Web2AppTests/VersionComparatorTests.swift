import Testing
import Foundation
@testable import Web2App

@Suite("VersionComparator Tests")
struct VersionComparatorTests {

    @Test("Parses standard semver")
    func parseStandardSemver() throws {
        let v = try VersionComparator.parse("1.2.3")
        #expect(v.major == 1)
        #expect(v.minor == 2)
        #expect(v.patch == 3)
    }

    @Test("Parses two-component version, defaults patch to 0")
    func parseTwoComponent() throws {
        let v = try VersionComparator.parse("1.0")
        #expect(v == SemanticVersion(major: 1, minor: 0, patch: 0))
    }

    @Test("Parses single-component version, defaults minor and patch to 0")
    func parseSingleComponent() throws {
        let v = try VersionComparator.parse("2")
        #expect(v == SemanticVersion(major: 2, minor: 0, patch: 0))
    }

    @Test("Strips leading v prefix")
    func stripVPrefix() throws {
        let v = try VersionComparator.parse("v2.1.0")
        #expect(v.major == 2)
        #expect(v.minor == 1)
        #expect(v.patch == 0)
    }

    @Test("Strips leading V prefix (uppercase)")
    func stripUppercaseVPrefix() throws {
        let v = try VersionComparator.parse("V3.0.1")
        #expect(v.major == 3)
        #expect(v.patch == 1)
    }

    @Test("Trims whitespace")
    func trimsWhitespace() throws {
        let v = try VersionComparator.parse("  1.5.0  ")
        #expect(v == SemanticVersion(major: 1, minor: 5, patch: 0))
    }

    @Test("Newer version detected correctly")
    func newerVersionDetected() throws {
        #expect(try VersionComparator.isNewer(remote: "1.1.0", thanLocal: "1.0") == true)
        #expect(try VersionComparator.isNewer(remote: "2.0.0", thanLocal: "1.9.9") == true)
        #expect(try VersionComparator.isNewer(remote: "1.0.1", thanLocal: "1.0.0") == true)
    }

    @Test("Same version is not newer")
    func sameVersionNotNewer() throws {
        #expect(try VersionComparator.isNewer(remote: "1.0.0", thanLocal: "1.0") == false)
        #expect(try VersionComparator.isNewer(remote: "1.0", thanLocal: "1.0.0") == false)
    }

    @Test("Older version is not newer")
    func olderVersionNotNewer() throws {
        #expect(try VersionComparator.isNewer(remote: "0.9.0", thanLocal: "1.0") == false)
        #expect(try VersionComparator.isNewer(remote: "1.0.0", thanLocal: "1.0.1") == false)
    }

    @Test("v prefix works with isNewer")
    func vPrefixWithComparison() throws {
        #expect(try VersionComparator.isNewer(remote: "v1.1.0", thanLocal: "1.0") == true)
        #expect(try VersionComparator.isNewer(remote: "v1.0.0", thanLocal: "v1.0.0") == false)
    }

    @Test("Empty string throws error")
    func emptyStringThrows() {
        #expect(throws: VersionParseError.self) {
            try VersionComparator.parse("")
        }
    }

    @Test("Non-numeric string throws error")
    func nonNumericThrows() {
        #expect(throws: VersionParseError.self) {
            try VersionComparator.parse("abc")
        }
    }

    @Test("Too many components throws error")
    func tooManyComponentsThrows() {
        #expect(throws: VersionParseError.self) {
            try VersionComparator.parse("1.2.3.4")
        }
    }

    @Test("SemanticVersion description format")
    func descriptionFormat() throws {
        let v = try VersionComparator.parse("1.2.3")
        #expect(v.description == "1.2.3")
    }
}
