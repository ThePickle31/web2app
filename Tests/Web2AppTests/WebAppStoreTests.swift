import Testing
import Foundation
@testable import Web2App

@Suite("WebAppStore Tests")
struct WebAppStoreTests {

    @MainActor
    @Test("Store initializes with empty list when no file exists")
    func initEmptyList() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("webapps.json")
        let store = WebAppStore(storageURL: tempURL)

        #expect(store.apps.isEmpty)
    }

    @MainActor
    @Test("Add and persist web app")
    func addAndPersist() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempURL = tempDir.appendingPathComponent("webapps.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = WebAppStore(storageURL: tempURL)
        let app = WebApp(name: "Test", url: URL(string: "https://example.com")!)

        store.add(app)

        #expect(store.apps.count == 1)
        #expect(store.apps.first?.name == "Test")

        // Verify persistence by loading a new store from the same URL
        let store2 = WebAppStore(storageURL: tempURL)
        #expect(store2.apps.count == 1)
        #expect(store2.apps.first?.id == app.id)
    }

    @MainActor
    @Test("Update web app")
    func updateApp() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempURL = tempDir.appendingPathComponent("webapps.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = WebAppStore(storageURL: tempURL)
        var app = WebApp(name: "Original", url: URL(string: "https://example.com")!)
        store.add(app)

        app.name = "Updated"
        store.update(app)

        #expect(store.apps.first?.name == "Updated")
    }

    @MainActor
    @Test("Delete web app")
    func deleteApp() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempURL = tempDir.appendingPathComponent("webapps.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = WebAppStore(storageURL: tempURL)
        let app = WebApp(name: "ToDelete", url: URL(string: "https://example.com")!)
        store.add(app)

        #expect(store.apps.count == 1)
        store.delete(app)
        #expect(store.apps.isEmpty)
    }

    @MainActor
    @Test("Move web apps")
    func moveApps() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let tempURL = tempDir.appendingPathComponent("webapps.json")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = WebAppStore(storageURL: tempURL)
        let app1 = WebApp(name: "First", url: URL(string: "https://first.com")!)
        let app2 = WebApp(name: "Second", url: URL(string: "https://second.com")!)
        store.add(app1)
        store.add(app2)

        store.move(from: IndexSet(integer: 1), to: 0)
        #expect(store.apps.first?.name == "Second")
    }
}
