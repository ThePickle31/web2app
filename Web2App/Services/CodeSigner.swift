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

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    logger.error("Code signing failed: \(errorMessage)")
                    continuation.resume(throwing: CodeSignerError.signingFailed(errorMessage))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Successfully signed \(appURL.lastPathComponent)")
    }

    /// Verifies the code signature of a signed .app bundle.
    static func verify(appURL: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--verify", "--deep", appURL.path(percentEncoded: false)]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: CodeSignerError.verificationFailed(errorMessage))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        logger.info("Signature verified for \(appURL.lastPathComponent)")
    }
}

enum CodeSignerError: LocalizedError {
    case signingFailed(String)
    case verificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .signingFailed(let message):
            return "Code signing failed: \(message)"
        case .verificationFailed(let message):
            return "Signature verification failed: \(message)"
        }
    }
}
