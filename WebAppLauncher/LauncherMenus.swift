import Cocoa

struct LauncherMenus {

    let appName: String

    func buildMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        mainMenu.addItem(buildAppMenuItem())
        mainMenu.addItem(buildEditMenuItem())
        mainMenu.addItem(buildViewMenuItem())
        mainMenu.addItem(buildWindowMenuItem())
        mainMenu.addItem(buildHelpMenuItem())
        return mainMenu
    }

    // MARK: - App Menu

    private func buildAppMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu()

        let aboutItem = NSMenuItem(
            title: "About \(appName)",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        menu.addItem(aboutItem)
        menu.addItem(.separator())

        let hideItem = NSMenuItem(
            title: "Hide \(appName)",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        menu.addItem(hideItem)

        let hideOthersItem = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(hideOthersItem)

        let showAllItem = NSMenuItem(
            title: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        menu.addItem(showAllItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit \(appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - Edit Menu

    private func buildEditMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: "Edit")

        let undoItem = NSMenuItem(
            title: "Undo",
            action: Selector(("undo:")),
            keyEquivalent: "z"
        )
        menu.addItem(undoItem)

        let redoItem = NSMenuItem(
            title: "Redo",
            action: Selector(("redo:")),
            keyEquivalent: "z"
        )
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(redoItem)

        menu.addItem(.separator())

        let cutItem = NSMenuItem(
            title: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        menu.addItem(cutItem)

        let copyItem = NSMenuItem(
            title: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        menu.addItem(copyItem)

        let pasteItem = NSMenuItem(
            title: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        menu.addItem(pasteItem)

        let selectAllItem = NSMenuItem(
            title: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        menu.addItem(selectAllItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - View Menu

    private func buildViewMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: "View")

        let backItem = NSMenuItem(
            title: "Back",
            action: #selector(WebAppWindowController.goBack(_:)),
            keyEquivalent: "["
        )
        menu.addItem(backItem)

        let forwardItem = NSMenuItem(
            title: "Forward",
            action: #selector(WebAppWindowController.goForward(_:)),
            keyEquivalent: "]"
        )
        menu.addItem(forwardItem)

        let reloadItem = NSMenuItem(
            title: "Reload",
            action: #selector(WebAppWindowController.reload(_:)),
            keyEquivalent: "r"
        )
        menu.addItem(reloadItem)

        menu.addItem(.separator())

        let zoomInItem = NSMenuItem(
            title: "Zoom In",
            action: #selector(WebAppWindowController.zoomIn(_:)),
            keyEquivalent: "="
        )
        menu.addItem(zoomInItem)

        let zoomOutItem = NSMenuItem(
            title: "Zoom Out",
            action: #selector(WebAppWindowController.zoomOut(_:)),
            keyEquivalent: "-"
        )
        menu.addItem(zoomOutItem)

        menu.addItem(.separator())

        let fullScreenItem = NSMenuItem(
            title: "Enter Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        )
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(fullScreenItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - Window Menu

    private func buildWindowMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: "Window")

        let minimizeItem = NSMenuItem(
            title: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        menu.addItem(minimizeItem)

        let zoomItem = NSMenuItem(
            title: "Zoom",
            action: #selector(NSWindow.performZoom(_:)),
            keyEquivalent: ""
        )
        menu.addItem(zoomItem)

        menu.addItem(.separator())

        let bringAllItem = NSMenuItem(
            title: "Bring All to Front",
            action: #selector(NSApplication.arrangeInFront(_:)),
            keyEquivalent: ""
        )
        menu.addItem(bringAllItem)

        menuItem.submenu = menu
        return menuItem
    }

    // MARK: - Help Menu

    private func buildHelpMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        let menu = NSMenu(title: "Help")

        let openInBrowserItem = NSMenuItem(
            title: "Open in Browser",
            action: #selector(WebAppWindowController.openInBrowser(_:)),
            keyEquivalent: ""
        )
        menu.addItem(openInBrowserItem)

        menuItem.submenu = menu
        return menuItem
    }
}
