import Foundation

struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    var description: String {
        "\(major).\(minor).\(patch)"
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
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
    /// Parses a version string like "1.0", "1.0.0", or "v1.2.3" into a SemanticVersion.
    /// Missing components default to 0 (e.g., "1.0" becomes 1.0.0).
    static func parse(_ string: String) throws -> SemanticVersion {
        var cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("v") {
            cleaned = String(cleaned.dropFirst())
        }

        let parts = cleaned.split(separator: ".").compactMap { Int($0) }
        guard !parts.isEmpty, parts.count <= 3,
              parts.count == cleaned.split(separator: ".").count else {
            throw VersionParseError.invalidFormat(string)
        }

        return SemanticVersion(
            major: parts[0],
            minor: parts.count > 1 ? parts[1] : 0,
            patch: parts.count > 2 ? parts[2] : 0
        )
    }

    /// Returns true if remoteVersion is newer than localVersion.
    static func isNewer(remote: String, thanLocal local: String) throws -> Bool {
        let remoteVersion = try parse(remote)
        let localVersion = try parse(local)
        return remoteVersion > localVersion
    }
}
