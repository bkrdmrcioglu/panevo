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

// Single owner of the managers: each WindowManager/HotKeyManager installs global
// event monitors and Carbon hotkeys, so a second instance causes double snaps
// and silently failing shortcuts.
final class AppServices {
    static let shared = AppServices()

    let displayManager: DisplayManager
    let windowManager: WindowManager
    let hotKeyManager: HotKeyManager
    let layoutProfileManager: LayoutProfileManager

    private init() {
        displayManager = DisplayManager()
        windowManager = WindowManager(displayManager: displayManager, accessibilityManager: AccessibilityManager.shared)
        hotKeyManager = HotKeyManager(windowManager: windowManager)
        layoutProfileManager = LayoutProfileManager(accessibilityManager: AccessibilityManager.shared, displayManager: displayManager)
    }

    func makeViewModel() -> PanevoViewModel {
        PanevoViewModel(
            windowManager: windowManager,
            hotKeyManager: hotKeyManager,
            displayManager: displayManager,
            accessibilityManager: AccessibilityManager.shared,
            settingsManager: SettingsManager.shared,
            layoutProfileManager: layoutProfileManager
        )
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
        let services = AppServices.shared
        settingsManager = SettingsManager.shared
        displayManager = services.displayManager
        accessibilityManager = AccessibilityManager.shared
        windowManager = services.windowManager
        hotKeyManager = services.hotKeyManager
        statusBarManager = StatusBarManager(hotKeyManager: services.hotKeyManager, settingsManager: SettingsManager.shared, windowManager: services.windowManager)
        displayProfileService = DisplayProfileService(
            displayManager: services.displayManager,
            layoutProfileManager: services.layoutProfileManager
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
