import Foundation
import os

enum UpdateChannel: String, Sendable {
    case stable
    case beta
}

struct GitHubRelease: Sendable {
    let tagName: String
    let version: String
    let dmgDownloadURL: URL
    let releaseNotes: String?
    let prerelease: Bool
}

enum AppUpdateServiceError: LocalizedError {
    case noReleasesFound
    case noDMGAsset
    case invalidResponse(Int)
    case downloadFailed(String)
    case dmgMountFailed(String)
    case appNotFoundInDMG
    case replacementFailed(String)

    var errorDescription: String? {
        switch self {
        case .noReleasesFound:
            return "No releases found on GitHub"
        case .noDMGAsset:
            return "Release does not contain a DMG asset"
        case .invalidResponse(let code):
            return "GitHub API returned status \(code)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .dmgMountFailed(let message):
            return "Failed to mount DMG: \(message)"
        case .appNotFoundInDMG:
            return "Web2App.app not found in mounted DMG"
        case .replacementFailed(let message):
            return "Failed to replace app: \(message)"
        }
    }
}

actor AppUpdateService {
    private static let logger = Logger(subsystem: "com.web2app", category: "AppUpdateService")
    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/ThePickle31/web2app/releases/latest")!
    private static let allReleasesURL = URL(string: "https://api.github.com/repos/ThePickle31/web2app/releases")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Check for Latest Release

    func checkForLatestRelease(channel: UpdateChannel = .stable) async throws -> GitHubRelease {
        let url = channel == .stable ? Self.latestReleaseURL : Self.allReleasesURL
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Web2App-Updater", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppUpdateServiceError.noReleasesFound
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppUpdateServiceError.invalidResponse(httpResponse.statusCode)
        }

        let json: [String: Any]

        if channel == .stable {
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AppUpdateServiceError.noReleasesFound
            }
            json = obj
        } else {
            guard let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = array.first(where: { $0["prerelease"] as? Bool == true }) else {
                throw AppUpdateServiceError.noReleasesFound
            }
            json = first
        }

        guard let tagName = json["tag_name"] as? String,
              let assets = json["assets"] as? [[String: Any]] else {
            throw AppUpdateServiceError.noReleasesFound
        }

        guard let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
              let downloadURLString = dmgAsset["browser_download_url"] as? String,
              let downloadURL = URL(string: downloadURLString) else {
            throw AppUpdateServiceError.noDMGAsset
        }

        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        let releaseNotes = json["body"] as? String
        let isPrerelease = json["prerelease"] as? Bool ?? false

        Self.logger.info("Found latest release: \(tagName) (prerelease: \(isPrerelease))")
        return GitHubRelease(
            tagName: tagName,
            version: version,
            dmgDownloadURL: downloadURL,
            releaseNotes: releaseNotes,
            prerelease: isPrerelease
        )
    }

    // MARK: - Download DMG

    func downloadDMG(
        from url: URL,
        progressHandler: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Web2App-Update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let destinationURL = tempDir.appendingPathComponent("Web2App.dmg")

        var request = URLRequest(url: url)
        request.setValue("Web2App-Updater", forHTTPHeaderField: "User-Agent")

        let delegate = DownloadProgressDelegate(handler: progressHandler)
        let (downloadedURL, response) = try await session.download(for: request, delegate: delegate)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppUpdateServiceError.downloadFailed("Server returned an error")
        }

        try FileManager.default.moveItem(at: downloadedURL, to: destinationURL)
        Self.logger.info("Downloaded DMG to \(destinationURL.path(percentEncoded: false))")
        return destinationURL
    }

    // MARK: - Mount DMG

    func mountDMGAndLocateApp(dmgURL: URL) async throws -> (appURL: URL, mountPoint: String) {
        let mountPoint = FileManager.default.temporaryDirectory
            .appendingPathComponent("Web2App-mount-\(UUID().uuidString)")
            .path(percentEncoded: false)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", dmgURL.path(percentEncoded: false),
                             "-nobrowse", "-readonly", "-mountpoint", mountPoint]

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
                    continuation.resume(throwing: AppUpdateServiceError.dmgMountFailed(errorMessage))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        let mountURL = URL(fileURLWithPath: mountPoint)
        let appURL = mountURL.appendingPathComponent("Web2App.app")

        guard FileManager.default.fileExists(atPath: appURL.path(percentEncoded: false)) else {
            throw AppUpdateServiceError.appNotFoundInDMG
        }

        Self.logger.info("Mounted DMG at \(mountPoint), found Web2App.app")
        return (appURL: appURL, mountPoint: mountPoint)
    }

    // MARK: - Unmount DMG

    func unmountDMG(mountPoint: String) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", mountPoint, "-force"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            process.waitUntilExit()
            Self.logger.info("Unmounted DMG at \(mountPoint)")
        } catch {
            Self.logger.warning("Failed to unmount DMG at \(mountPoint): \(error.localizedDescription)")
        }
    }
}

// MARK: - Download Progress Delegate

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let handler: @Sendable (Double) -> Void

    init(handler: @Sendable @escaping (Double) -> Void) {
        self.handler = handler
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        handler(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(
        _: URLSession,
        downloadTask _: URLSessionDownloadTask,
        didFinishDownloadingTo _: URL
    ) {
        // Handled by the async download(for:delegate:) call
    }
}
