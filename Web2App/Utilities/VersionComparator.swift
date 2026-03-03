import Foundation

struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: String?

    init(major: Int, minor: Int, patch: Int, prerelease: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    var description: String {
        if let prerelease {
            return "\(major).\(minor).\(patch)-\(prerelease)"
        }
        return "\(major).\(minor).\(patch)"
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Per semver: pre-release < release (e.g. 1.0.0-beta.1 < 1.0.0)
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil):
            return false
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (.some(let left), .some(let right)):
            return Self.comparePrereleaseIdentifiers(left, right)
        }
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        lhs.major == rhs.major
            && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch
            && lhs.prerelease == rhs.prerelease
    }

    /// Compares pre-release identifiers per semver spec:
    /// numeric segments compare as integers, others compare lexicographically.
    private static func comparePrereleaseIdentifiers(_ lhs: String, _ rhs: String) -> Bool {
        let leftParts = lhs.split(separator: ".")
        let rightParts = rhs.split(separator: ".")

        for (l, r) in zip(leftParts, rightParts) {
            if l == r { continue }
            if let lInt = Int(l), let rInt = Int(r) {
                return lInt < rInt
            }
            return l < r
        }
        // Fewer fields = lower precedence (e.g. "beta" < "beta.1")
        return leftParts.count < rightParts.count
    }
}

enum VersionParseError: LocalizedError {
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let input):
            return "Invalid version format: \(input)"
        }
    }
}

struct VersionComparator {
    /// Parses a version string like "1.0", "1.0.0", "v1.2.3", or "1.0.0-beta.1" into a SemanticVersion.
    /// Missing components default to 0 (e.g., "1.0" becomes 1.0.0).
    /// Pre-release identifiers after a hyphen are preserved (e.g., "1.0.0-beta.1").
    static func parse(_ string: String) throws -> SemanticVersion {
        var cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("v") {
            cleaned = String(cleaned.dropFirst())
        }

        // Split off pre-release identifier (everything after first hyphen)
        var prerelease: String?
        if let hyphenIndex = cleaned.firstIndex(of: "-") {
            let prereleaseStr = String(cleaned[cleaned.index(after: hyphenIndex)...])
            if !prereleaseStr.isEmpty {
                prerelease = prereleaseStr
            }
            cleaned = String(cleaned[..<hyphenIndex])
        }

        let parts = cleaned.split(separator: ".").compactMap { Int($0) }
        guard !parts.isEmpty, parts.count <= 3,
              parts.count == cleaned.split(separator: ".").count else {
            throw VersionParseError.invalidFormat(string)
        }

        return SemanticVersion(
            major: parts[0],
            minor: parts.count > 1 ? parts[1] : 0,
            patch: parts.count > 2 ? parts[2] : 0,
            prerelease: prerelease
        )
    }

    /// Returns true if remoteVersion is newer than localVersion.
    static func isNewer(remote: String, thanLocal local: String) throws -> Bool {
        let remoteVersion = try parse(remote)
        let localVersion = try parse(local)
        return remoteVersion > localVersion
    }
}
