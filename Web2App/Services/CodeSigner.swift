import Foundation
import os

struct CodeSigner {
    private static let logger = Logger(subsystem: "com.web2app", category: "CodeSigner")

    /// Performs ad-hoc code signing on the given .app bundle.
    static func sign(appURL: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--force", "--deep", "--sign", "-", appURL.path(percentEncoded: false)]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            logger.error("Code signing failed: \(errorMessage)")
            throw CodeSignerError.signingFailed(errorMessage)
        }

        logger.info("Successfully signed \(appURL.lastPathComponent)")
    }
}

enum CodeSignerError: LocalizedError {
    case signingFailed(String)

    var errorDescription: String? {
        switch self {
        case .signingFailed(let message):
            return "Code signing failed: \(message)"
        }
    }
}
