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
    private var windowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        setupManagers()
        requestAccessibilityPermission()
        observeWindowClosing()
    }

    // When the last visible window closes, drop out of the Dock and keep
    // living in the menu bar (Rectangle/Magnet-style behavior).
    private func observeWindowClosing() {
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                let visibleWindows = NSApp.windows.filter {
                    $0.isVisible && $0.canBecomeKey && !($0 is SnapOverlayWindow)
                }
                if visibleWindows.isEmpty {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }

    // Clicking the Dock icon (after re-activation) or reopening brings the window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.setActivationPolicy(.regular)
        if !flag {
            for window in NSApp.windows where window.canBecomeKey {
                window.makeKeyAndOrderFront(nil)
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        return true
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
