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
    private var displayProfileService: DisplayProfileService?
    private var trustPollTimer: Timer?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        setupManagers()
        requestAccessibilityPermission()
        relaunchWhenAccessibilityGranted()
        showOnboardingIfNeeded()
        UpdateChecker.shared.checkForUpdates()
    }

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

        let layoutManager = LayoutProfileManager(
            accessibilityManager: accessibilityManager!,
            displayManager: displayManager!
        )
        displayProfileService = DisplayProfileService(
            displayManager: displayManager!,
            layoutProfileManager: layoutManager
        )
    }

    private func requestAccessibilityPermission() {
        accessibilityManager?.requestAccessibilityPermission()
    }

    private func showOnboardingIfNeeded() {
        guard !SettingsManager.shared.hasCompletedOnboarding else { return }

        let view = OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Panevo"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
