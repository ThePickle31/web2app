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

    // MARK: - Pre-release version tests

    @Test("Parses version with pre-release identifier")
    func parsePrereleaseVersion() throws {
        let v = try VersionComparator.parse("0.0.3-beta.1")
        #expect(v.major == 0)
        #expect(v.minor == 0)
        #expect(v.patch == 3)
        #expect(v.prerelease == "beta.1")
    }

    @Test("Parses version with v prefix and pre-release")
    func parseVPrefixWithPrerelease() throws {
        let v = try VersionComparator.parse("v1.2.0-rc.1")
        #expect(v.major == 1)
        #expect(v.minor == 2)
        #expect(v.patch == 0)
        #expect(v.prerelease == "rc.1")
    }

    @Test("Pre-release is less than release with same base version")
    func prereleaseIsLessThanRelease() throws {
        let prerelease = try VersionComparator.parse("0.0.3-beta.1")
        let release = try VersionComparator.parse("0.0.3")
        #expect(prerelease < release)
        #expect(!(release < prerelease))
    }

    @Test("Pre-release numeric ordering")
    func prereleaseNumericOrdering() throws {
        let beta1 = try VersionComparator.parse("0.0.3-beta.1")
        let beta2 = try VersionComparator.parse("0.0.3-beta.2")
        #expect(beta1 < beta2)
        #expect(!(beta2 < beta1))
    }

    @Test("Pre-release versions with same identifiers are equal")
    func prereleaseEquality() throws {
        let a = try VersionComparator.parse("0.0.3-beta.1")
        let b = try VersionComparator.parse("0.0.3-beta.1")
        #expect(a == b)
    }

    @Test("Higher base version beats pre-release of lower version")
    func higherBaseVersionWins() throws {
        let betaHigher = try VersionComparator.parse("0.0.4-beta.1")
        let releaseLower = try VersionComparator.parse("0.0.3")
        #expect(betaHigher > releaseLower)
    }

    @Test("isNewer works with pre-release local version")
    func isNewerWithPrereleaseLocal() throws {
        // Stable release is newer than its own pre-release
        #expect(try VersionComparator.isNewer(remote: "0.0.3", thanLocal: "0.0.3-beta.1") == true)
        // Same pre-release is not newer
        #expect(try VersionComparator.isNewer(remote: "0.0.3-beta.1", thanLocal: "0.0.3-beta.1") == false)
        // Higher beta is newer
        #expect(try VersionComparator.isNewer(remote: "0.0.3-beta.2", thanLocal: "0.0.3-beta.1") == true)
    }

    @Test("SemanticVersion description includes pre-release")
    func descriptionWithPrerelease() throws {
        let v = try VersionComparator.parse("1.2.3-beta.1")
        #expect(v.description == "1.2.3-beta.1")
    }
}
