import Foundation

enum URLValidationError: LocalizedError {
    case empty
    case invalidFormat
    case unsupportedScheme

    var errorDescription: String? {
        switch self {
        case .empty: return "URL cannot be empty"
        case .invalidFormat: return "Invalid URL format"
        case .unsupportedScheme: return "Only HTTP and HTTPS URLs are supported"
        }
    }
}

struct URLValidator {
    static func validate(_ input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw URLValidationError.empty }

        var urlString = trimmed
        if !urlString.contains("://") {
            urlString = "https://\(urlString)"
        }

        guard let url = URL(string: urlString) else {
            throw URLValidationError.invalidFormat
        }

        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw URLValidationError.unsupportedScheme
        }

        guard url.host() != nil else {
            throw URLValidationError.invalidFormat
        }

        return url
    }
}
