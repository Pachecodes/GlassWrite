import SwiftUI
import AppKit

@main
struct GlassWriteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(state: appDelegate.state)
        }
    }
}
