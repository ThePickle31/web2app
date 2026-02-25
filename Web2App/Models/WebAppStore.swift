import Foundation
import Observation
import os

@MainActor
@Observable
final class WebAppStore {
    private static let logger = Logger(subsystem: "com.web2app", category: "WebAppStore")

    private(set) var apps: [WebApp] = []
    private let storageURL: URL

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        load()
    }

    // MARK: - CRUD

    func add(_ app: WebApp) {
        apps.append(app)
        save()
    }

    func update(_ app: WebApp) {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else { return }
        apps[index] = app
        save()
    }

    func delete(_ app: WebApp) {
        removeGeneratedApp(app)
        apps.removeAll { $0.id == app.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            removeGeneratedApp(apps[index])
        }
        apps.remove(atOffsets: offsets)
        save()
    }

    private func removeGeneratedApp(_ app: WebApp) {
        guard let path = app.generatedAppPath else { return }

        let url = URL(fileURLWithPath: path).standardizedFileURL

        guard url.pathExtension == "app" else {
            Self.logger.error("Refusing to delete non-.app path: \(path)")
            return
        }

        // Validate path is within expected directories
        let expectedBase = Self.defaultStorageURL()
            .deletingLastPathComponent()
            .standardizedFileURL
        let homePath = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path()
        let applicationsPath = "/Applications/"
        let urlPath = url.path()

        guard urlPath.hasPrefix(expectedBase.path()) || urlPath.hasPrefix(homePath) || urlPath.hasPrefix(applicationsPath) else {
            Self.logger.error("Refusing to delete app outside expected directory: \(path)")
            return
        }

        guard FileManager.default.fileExists(atPath: path) else { return }

        do {
            try FileManager.default.removeItem(at: url)
            Self.logger.info("Deleted generated app at \(path)")
        } catch {
            Self.logger.error("Failed to delete generated app: \(error.localizedDescription)")
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path(percentEncoded: false)) else {
            Self.logger.info("No existing data file found; starting with empty list")
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            apps = try decoder.decode([WebApp].self, from: data)
            Self.logger.info("Loaded \(self.apps.count) web app(s)")
        } catch {
            Self.logger.error("Failed to load web apps: \(error.localizedDescription)")
        }
    }

    private func save() {
        let directory = storageURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            Self.logger.error("Failed to create storage directory: \(error.localizedDescription)")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(apps)
            try data.write(to: storageURL, options: .atomic)
            Self.logger.info("Saved \(self.apps.count) web app(s)")
        } catch {
            Self.logger.error("Failed to save web apps: \(error.localizedDescription)")
        }
    }

    // MARK: - Storage Location

    private static func defaultStorageURL() -> URL {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            fatalError("Application Support directory not available")
        }
        return appSupport
            .appendingPathComponent("Web2App", isDirectory: true)
            .appendingPathComponent("webapps.json")
    }
}
