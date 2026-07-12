import Foundation
import AppKit
import Combine

class PanevoViewModel: ObservableObject {
    @Published var isAccessibilityEnabled: Bool = false
    @Published var displays: [DisplayInfo] = []
    @Published var allWindows: [ApplicationInfo] = []
    @Published var shortcuts: [KeyboardShortcut] = []
    @Published var layoutProfiles: [LayoutProfile] = []
    @Published var currentLayout: LayoutProfile?
    @Published var isLoading: Bool = false

    private let windowManager: WindowManager
    private let hotKeyManager: HotKeyManager
    private let displayManager: DisplayManager
    private let accessibilityManager: AccessibilityManager
    private let settingsManager: SettingsManager

    private let layoutProfileManager: LayoutProfileManager
    private var cancellables = Set<AnyCancellable>()

    init(windowManager: WindowManager, hotKeyManager: HotKeyManager, displayManager: DisplayManager,
         accessibilityManager: AccessibilityManager, settingsManager: SettingsManager) {
        self.windowManager = windowManager
        self.hotKeyManager = hotKeyManager
        self.displayManager = displayManager
        self.accessibilityManager = accessibilityManager
        self.settingsManager = settingsManager
        self.layoutProfileManager = LayoutProfileManager(
            accessibilityManager: accessibilityManager,
            displayManager: displayManager
        )

        setupBindings()
        checkAccessibility()
        loadData()
    }

    // MARK: - Setup

    private func setupBindings() {
        displayManager.$displays
            .assign(to: &$displays)

        settingsManager.$shortcuts
            .assign(to: &$shortcuts)
    }

    private func checkAccessibility() {
        isAccessibilityEnabled = accessibilityManager.isAccessibilityEnabled

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.isAccessibilityEnabled = self?.accessibilityManager.isAccessibilityEnabled ?? false
        }
    }

    private func loadData() {
        isLoading = true
        DispatchQueue.global().async { [weak self] in
            self?.allWindows = self?.windowManager.getAllWindows() ?? []
            self?.layoutProfiles = self?.settingsManager.getLayoutProfiles() ?? []
            DispatchQueue.main.async {
                self?.isLoading = false
            }
        }
    }

    // MARK: - Window Snapping

    func snapWindow(to position: WindowPosition) {
        windowManager.snapWindow(to: position)
    }

    func moveWindowToNextDisplay() {
        windowManager.moveWindowToNextDisplay()
    }

    func moveWindowToPreviousDisplay() {
        windowManager.moveWindowToPreviousDisplay()
    }

    // MARK: - Shortcuts Management

    func updateShortcut(_ shortcut: KeyboardShortcut) {
        // Persisting posts .panevoShortcutsChanged, which re-registers hotkeys.
        settingsManager.updateShortcut(shortcut)
    }

    func resetShortcuts() {
        settingsManager.resetShortcutsToDefaults()
    }

    func detectShortcutConflicts() -> [(KeyboardShortcut, KeyboardShortcut)] {
        return hotKeyManager.detectConflicts()
    }

    // MARK: - Layout Profiles

    func saveLayoutProfile(_ profile: LayoutProfile) {
        settingsManager.saveLayoutProfile(profile)
        loadData()
    }

    func deleteLayoutProfile(_ profile: LayoutProfile) {
        settingsManager.deleteLayoutProfile(profile)
        loadData()
    }

    func applyLayoutProfile(_ profile: LayoutProfile) {
        currentLayout = profile
        layoutProfileManager.apply(profile)
    }

    func saveCurrentLayout(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let profileName = trimmed.isEmpty ? "Layout \(layoutProfiles.count + 1)" : trimmed
        let profile = layoutProfileManager.captureCurrentLayout(name: profileName)
        saveLayoutProfile(profile)
    }

    func createPresetLayout(_ preset: PresetLayout) {
        let profile = preset.createDefaultProfile()
        saveLayoutProfile(profile)
    }

    // MARK: - Settings

    func requestAccessibilityPermission() {
        accessibilityManager.requestAccessibilityPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAccessibility()
        }
    }

    func updateSettings() {
        settingsManager.saveSettings()
    }

    func refreshWindows() {
        loadData()
    }
}
