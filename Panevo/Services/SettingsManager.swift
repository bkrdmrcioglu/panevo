import Foundation
import Combine
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private enum Keys {
        static let shortcuts = "panevo.shortcuts"
        static let layoutProfiles = "panevo.layoutProfiles"
        static let animationStyle = "panevo.animationStyle"
        static let showOverlay = "panevo.showOverlay"
        static let launchAtLogin = "panevo.launchAtLogin"
        static let windowGap = "panevo.windowGap"
        static let dragEdgeThreshold = "panevo.dragEdgeThreshold"
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published var shortcuts: [KeyboardShortcut] = []
    @Published var layoutProfiles: [LayoutProfile] = []

    @Published var animationStyle: SnapAnimationStyle {
        didSet { defaults.set(animationStyle.rawValue, forKey: Keys.animationStyle) }
    }

    @Published var showOverlay: Bool {
        didSet { defaults.set(showOverlay, forKey: Keys.showOverlay) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var windowGap: Double {
        didSet { defaults.set(windowGap, forKey: Keys.windowGap) }
    }

    @Published var dragEdgeThreshold: Double {
        didSet { defaults.set(dragEdgeThreshold, forKey: Keys.dragEdgeThreshold) }
    }

    private init() {
        let styleRaw = defaults.string(forKey: Keys.animationStyle) ?? SnapAnimationStyle.instant.rawValue
        animationStyle = SnapAnimationStyle(rawValue: styleRaw) ?? .instant
        showOverlay = defaults.object(forKey: Keys.showOverlay) as? Bool ?? true
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        windowGap = defaults.object(forKey: Keys.windowGap) as? Double ?? 0
        dragEdgeThreshold = defaults.object(forKey: Keys.dragEdgeThreshold) as? Double ?? 50

        loadSettings()
    }

    // MARK: - Persistence

    func loadSettings() {
        if let data = defaults.data(forKey: Keys.shortcuts),
           let saved = try? decoder.decode([KeyboardShortcut].self, from: data),
           !saved.isEmpty {
            shortcuts = saved
        } else {
            shortcuts = KeyboardShortcut.defaultShortcuts
        }

        // Every action appears in the list so users can assign a shortcut to any of them.
        let existingActions = Set(shortcuts.map { $0.action })
        for action in SnapAction.allCases where !existingActions.contains(action) {
            shortcuts.append(KeyboardShortcut(action: action, keyCode: 0, modifiers: 0, isEnabled: false))
        }

        if let data = defaults.data(forKey: Keys.layoutProfiles),
           let saved = try? decoder.decode([LayoutProfile].self, from: data) {
            layoutProfiles = saved
        }
    }

    func saveSettings() {
        persistShortcuts()
        persistLayoutProfiles()
    }

    private func persistShortcuts() {
        if let data = try? encoder.encode(shortcuts) {
            defaults.set(data, forKey: Keys.shortcuts)
        }
    }

    private func persistLayoutProfiles() {
        if let data = try? encoder.encode(layoutProfiles) {
            defaults.set(data, forKey: Keys.layoutProfiles)
        }
    }

    // MARK: - Shortcuts

    func updateShortcut(_ shortcut: KeyboardShortcut) {
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index] = shortcut
        } else {
            shortcuts.append(shortcut)
        }
        persistShortcuts()
        NotificationCenter.default.post(name: .panevoShortcutsChanged, object: nil)
    }

    func resetShortcutsToDefaults() {
        shortcuts = KeyboardShortcut.defaultShortcuts
        persistShortcuts()
        NotificationCenter.default.post(name: .panevoShortcutsChanged, object: nil)
    }

    // MARK: - Layout Profiles

    func getLayoutProfiles() -> [LayoutProfile] {
        return layoutProfiles
    }

    func saveLayoutProfile(_ profile: LayoutProfile) {
        if let index = layoutProfiles.firstIndex(where: { $0.id == profile.id }) {
            layoutProfiles[index] = profile
        } else {
            layoutProfiles.append(profile)
        }
        persistLayoutProfiles()
    }

    func deleteLayoutProfile(_ profile: LayoutProfile) {
        layoutProfiles.removeAll { $0.id == profile.id }
        persistLayoutProfiles()
    }

    // MARK: - Launch at Login

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Panevo: launch at login change failed: %@", error.localizedDescription)
        }
    }
}
