import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) weak var shared: AppDelegate?

    let state = AppState()
    private var panelController: FloatingPanelController?
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        NSApp.setActivationPolicy(.accessory)
        state.bootstrap()
        panelController = FloatingPanelController(state: state)
        panelController?.show()
        installMenuBarItem()
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "✦"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Overlay", action: #selector(showOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Analyze Now", action: #selector(analyzeNow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Request Accessibility Permission", action: #selector(requestAX), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func showOverlay() { panelController?.show() }
    @objc private func analyzeNow() { state.analyzeCurrentSnippet(force: true) }
    @objc private func requestAX() { state.requestAccessibilityPermission() }
    @objc func openSettings() {
        // The SwiftUI Settings scene is unreliable for a menu-bar/accessory-only app.
        // Keep an explicit window so the ✦ Settings menu and overlay button always work.
        if settingsWindowController == nil {
            let hosting = NSHostingController(rootView: SettingsView(state: state))
            let window = NSWindow(contentViewController: hosting)
            window.title = "GlassWrite Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 540, height: 390))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindowController = NSWindowController(window: window)
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    @objc private func quit() { NSApp.terminate(nil) }
}
