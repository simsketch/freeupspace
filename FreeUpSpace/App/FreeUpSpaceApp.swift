import SwiftUI
import AppKit
import CleanupEngine
import Permissions

// Manual app entry point since SwiftUI Scene doesn't create windows
// when compiled outside of Xcode
@main
enum FreeUpSpaceApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = FreeUpSpaceAppDelegate()
        app.delegate = delegate
        app.run()
    }
}

final class FreeUpSpaceAppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow!
    var statusItem: NSStatusItem?
    let appState = AppState()
    let permissionManager = PermissionManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create main window
        let contentView = ContentView()
            .environment(appState)
            .environment(permissionManager)

        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        mainWindow.title = "FreeUpSpace"
        mainWindow.minSize = NSSize(width: 800, height: 550)
        mainWindow.contentView = NSHostingView(rootView: contentView)
        mainWindow.center()
        mainWindow.makeKeyAndOrderFront(nil)

        // Setup menu bar extra
        setupMenuBarExtra()

        // Setup main menu
        setupMainMenu()

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    private func setupMenuBarExtra() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "externaldrive.badge.minus", accessibilityDescription: "FreeUpSpace")
        }

        let menuBarView = MenuBarView()
            .environment(appState)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 350)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: menuBarView)

        statusItem?.button?.action = #selector(togglePopover(_:))
        statusItem?.button?.target = self

        // Store popover reference
        objc_setAssociatedObject(self, &popoverKey, popover, .OBJC_ASSOCIATION_RETAIN)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button,
              let popover = objc_getAssociatedObject(self, &popoverKey) as? NSPopover else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About FreeUpSpace", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(openSettings(_:)), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit FreeUpSpace", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Scan", action: #selector(newScan(_:)), keyEquivalent: "r")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func openSettings(_ sender: Any?) {
        let settingsView = SettingsView()
            .environment(appState)
            .environment(permissionManager)

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Settings"
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    @objc private func newScan(_ sender: Any?) {
        appState.startScan()
    }
}

private var popoverKey: UInt8 = 0

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.showOnboarding {
            WelcomeView()
        } else {
            MainView()
        }
    }
}
