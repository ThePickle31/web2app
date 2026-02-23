import Cocoa
import WebKit

class WebAppWindowController: NSObject, NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate {

    private let config: LauncherConfig
    private var window: NSWindow?
    private var webView: WKWebView?
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

        let win = NSWindow(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        win.minSize = NSSize(width: 400, height: 300)
        win.collectionBehavior = [.fullScreenPrimary]
        win.setFrameAutosaveName(config.appName)
        win.title = config.appName
        win.delegate = self
        win.center()

        self.window = win
    }

    private func setupWebView() {
        guard let window else { return }

        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true

        let dataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = dataStore

        guard let contentView = window.contentView else { return }

        let wv = WKWebView(frame: contentView.bounds, configuration: configuration)
        wv.autoresizingMask = [.width, .height]
        wv.navigationDelegate = self
        wv.uiDelegate = self

        let sanitizedName = config.appName
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .filter { !$0.isNewline }
        wv.customUserAgent = (wv.value(forKey: "userAgent") as? String ?? "") + " \(sanitizedName)"
        wv.allowsBackForwardNavigationGestures = true

        contentView.addSubview(wv)

        titleObservation = wv.observe(\.title, options: [.new]) { [weak self] _, change in
            guard let title = change.newValue as? String, !title.isEmpty else { return }
            Task { @MainActor [weak self] in
                self?.window?.title = title
            }
        }

        self.webView = wv

        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func loadURL() {
        let request = URLRequest(url: config.url)
        webView?.load(request)
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
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
        completionHandler: @escaping @MainActor @Sendable () -> Void
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
        completionHandler: @escaping @MainActor @Sendable (Bool) -> Void
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
        completionHandler: @escaping @MainActor @Sendable (String?) -> Void
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
        webView?.goBack()
    }

    @objc func goForward(_ sender: Any?) {
        webView?.goForward()
    }

    @objc func reload(_ sender: Any?) {
        webView?.reload()
    }

    @objc func zoomIn(_ sender: Any?) {
        guard let webView else { return }
        webView.pageZoom *= 1.1
    }

    @objc func zoomOut(_ sender: Any?) {
        guard let webView else { return }
        webView.pageZoom /= 1.1
    }

    @objc func openInBrowser(_ sender: Any?) {
        guard let currentURL = webView?.url else { return }
        NSWorkspace.shared.open(currentURL)
    }
}
