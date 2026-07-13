import SwiftUI
import AppKit

@main
struct PanevoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?
    private var windowManager: WindowManager?
    private var hotKeyManager: HotKeyManager?
    private var accessibilityManager: AccessibilityManager?
    private var settingsManager: SettingsManager?
    private var displayManager: DisplayManager?
    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement keeps the app out of the Dock; it lives in the menu bar.
        // Activate so the main window is visible on first launch.
        NSApp.activate(ignoringOtherApps: true)

        setupManagers()
        requestAccessibilityPermission()
    }

    private func setupManagers() {
        settingsManager = SettingsManager.shared
        displayManager = DisplayManager()
        accessibilityManager = AccessibilityManager.shared
        windowManager = WindowManager(displayManager: displayManager!, accessibilityManager: accessibilityManager!)
        hotKeyManager = HotKeyManager(windowManager: windowManager!)
        statusBarManager = StatusBarManager(hotKeyManager: hotKeyManager!, settingsManager: settingsManager!, windowManager: windowManager)
    }

    private func requestAccessibilityPermission() {
        accessibilityManager?.requestAccessibilityPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
