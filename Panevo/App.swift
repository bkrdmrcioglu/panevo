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
    private var trustPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement keeps the app out of the Dock; it lives in the menu bar.
        // Activate so the main window is visible on first launch.
        NSApp.activate(ignoringOtherApps: true)

        setupManagers()
        requestAccessibilityPermission()
        relaunchWhenAccessibilityGranted()
    }

    // macOS does not fully apply a newly granted Accessibility permission to an
    // already-running process. Watch for the grant and relaunch automatically,
    // the same way Rectangle does.
    private func relaunchWhenAccessibilityGranted() {
        guard accessibilityManager?.isAccessibilityEnabled == false else { return }

        trustPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard self?.accessibilityManager?.isAccessibilityEnabled == true else { return }
            timer.invalidate()
            self?.relaunch()
        }
    }

    private func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", Bundle.main.bundlePath]
        try? process.run()
        NSApp.terminate(nil)
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
