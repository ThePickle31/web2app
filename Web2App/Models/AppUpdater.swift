import AppKit
import Foundation
import Observation
import os

enum UpdateStatus: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable(version: String)
    case downloading(progress: Double)
    case installing
    case error(String)
}

@MainActor
@Observable
final class AppUpdater {
    private static let logger = Logger(subsystem: "com.web2app", category: "AppUpdater")

    private(set) var status: UpdateStatus = .idle
    private(set) var availableRelease: GitHubRelease?

    private let service = AppUpdateService()
    private var downloadedDMGURL: URL?
    private var updateTask: Task<Void, Never>?

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    // MARK: - Check for Updates

    func checkForUpdates() {
        updateTask?.cancel()
        updateTask = Task {
            status = .checking

            do {
                let channelRaw = UserDefaults.standard.string(forKey: "updateChannel") ?? "stable"
                let channel = UpdateChannel(rawValue: channelRaw) ?? .stable
                let release = try await service.checkForLatestRelease(channel: channel)
                if Task.isCancelled { return }

                let isNewer = try VersionComparator.isNewer(
                    remote: release.version,
                    thanLocal: currentVersion
                )

                if isNewer {
                    availableRelease = release
                    status = .updateAvailable(version: release.version)
                    Self.logger.info("Update available: \(release.version)")
                } else {
                    availableRelease = nil
                    status = .upToDate
                    Self.logger.info("App is up to date (\(self.currentVersion))")
                }
            } catch {
                if !Task.isCancelled {
                    status = .error(error.localizedDescription)
                    Self.logger.error("Update check failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Download & Install

    func downloadAndInstall() {
        guard let release = availableRelease else { return }

        updateTask?.cancel()
        updateTask = Task {
            status = .downloading(progress: 0)

            do {
                let dmgURL = try await service.downloadDMG(
                    from: release.dmgDownloadURL
                ) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.status = .downloading(progress: progress)
                    }
                }

                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: dmgURL.deletingLastPathComponent())
                    return
                }

                downloadedDMGURL = dmgURL
                status = .installing

                let (newAppURL, mountPoint) = try await service.mountDMGAndLocateApp(dmgURL: dmgURL)
                try replaceAndRelaunch(newAppURL: newAppURL, mountPoint: mountPoint)

            } catch {
                if !Task.isCancelled {
                    status = .error(error.localizedDescription)
                    Self.logger.error("Update failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Cancel

    func cancelUpdate() {
        updateTask?.cancel()
        updateTask = nil
        if let dmgURL = downloadedDMGURL {
            try? FileManager.default.removeItem(at: dmgURL.deletingLastPathComponent())
            downloadedDMGURL = nil
        }
        status = .idle
    }

    // MARK: - Replace & Relaunch

    private func replaceAndRelaunch(newAppURL: URL, mountPoint: String) throws {
        let currentAppURL = Bundle.main.bundleURL.standardizedFileURL
        let currentAppPath = currentAppURL.path(percentEncoded: false)
        let newAppPath = newAppURL.path(percentEncoded: false)
        let pid = ProcessInfo.processInfo.processIdentifier
        let tempDirPath = downloadedDMGURL?.deletingLastPathComponent().path(percentEncoded: false) ?? ""

        // Shell script that waits for the app to exit, then replaces it.
        // Attempts direct copy first; falls back to admin privileges via osascript.
        let script = """
        #!/bin/bash
        # Wait for the current app process to exit (timeout after 30s)
        COUNTER=0
        while kill -0 \(pid) 2>/dev/null && [ $COUNTER -lt 60 ]; do
            sleep 0.5
            COUNTER=$((COUNTER+1))
        done

        # Try direct replacement first
        if rm -rf "\(currentAppPath)" 2>/dev/null && cp -R "\(newAppPath)" "\(currentAppPath)" 2>/dev/null; then
            : # Success
        else
            # Fall back to admin privileges
            osascript -e 'do shell script "rm -rf \\\"\(currentAppPath)\\\" && cp -R \\\"\(newAppPath)\\\" \\\"\(currentAppPath)\\\"" with administrator privileges'
        fi

        # Unmount the DMG
        hdiutil detach "\(mountPoint)" -force 2>/dev/null

        # Remove quarantine attribute
        xattr -dr com.apple.quarantine "\(currentAppPath)" 2>/dev/null

        # Relaunch the app
        open "\(currentAppPath)"

        # Clean up temp files
        rm -rf "\(tempDirPath)"

        # Remove this script
        rm -f "$0"
        """

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("web2app-update-\(UUID().uuidString).sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL.path(percentEncoded: false)
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path(percentEncoded: false)]
        try process.run()

        Self.logger.info("Launched update script, terminating app for replacement")
        NSApplication.shared.terminate(nil)
    }
}
