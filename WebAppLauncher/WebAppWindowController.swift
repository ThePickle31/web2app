import Cocoa
import WebKit

class WebAppWindowController: NSObject, NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate {

    private let config: LauncherConfig
    private var window: NSWindow!
    private var webView: WKWebView!
    private var titleObservation: NSKeyValueObservation?

    init(config: LauncherConfig) {
        self.config = config
        super.init()
    }

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupWindow()
        setupWebView()
        loadURL()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Setup

    private func setupMenuBar() {
        let menus = LauncherMenus(appName: config.appName)
        NSApplication.shared.mainMenu = menus.buildMainMenu()
    }

    private func setupWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 1200, height: 800)
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable
        ]

        window = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.minSize = NSSize(width: 400, height: 300)
        window.collectionBehavior = [.fullScreenPrimary]
        window.setFrameAutosaveName(config.appName)
        window.title = config.appName
        window.delegate = self
        window.center()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true

        let dataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = dataStore

        webView = WKWebView(frame: window.contentView!.bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = (webView.value(forKey: "userAgent") as? String ?? "") + " \(config.appName)"
        webView.allowsBackForwardNavigationGestures = true

        window.contentView!.addSubview(webView)

        titleObservation = webView.observe(\.title, options: [.new]) { [weak self] _, change in
            guard let self = self, let title = change.newValue as? String, !title.isEmpty else { return }
            self.window.title = title
        }

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func loadURL() {
        let request = URLRequest(url: config.url)
        webView.load(request)
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Open target="_blank" links in the same web view
        if navigationAction.targetFrame == nil || navigationAction.targetFrame?.isMainFrame == false {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = config.appName
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = config.appName
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = config.appName
        alert.informativeText = prompt
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.stringValue = defaultText ?? ""
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completionHandler(textField.stringValue)
        } else {
            completionHandler(nil)
        }
    }

    // MARK: - Menu Actions (First Responder Chain)

    @objc func goBack(_ sender: Any?) {
        webView.goBack()
    }

    @objc func goForward(_ sender: Any?) {
        webView.goForward()
    }

    @objc func reload(_ sender: Any?) {
        webView.reload()
    }

    @objc func zoomIn(_ sender: Any?) {
        webView.pageZoom *= 1.1
    }

    @objc func zoomOut(_ sender: Any?) {
        webView.pageZoom /= 1.1
    }

    @objc func openInBrowser(_ sender: Any?) {
        guard let currentURL = webView.url else { return }
        NSWorkspace.shared.open(currentURL)
    }
}
