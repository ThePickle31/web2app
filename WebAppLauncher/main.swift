import Cocoa

do {
    let config = try LauncherConfig()
    let app = NSApplication.shared
    let controller = WebAppWindowController(config: config)
    app.delegate = controller
    app.run()
} catch {
    let alert = NSAlert()
    alert.messageText = "Launch Failed"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .critical
    alert.runModal()
    exit(1)
}
