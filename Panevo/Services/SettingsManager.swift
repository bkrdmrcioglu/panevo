import Foundation
import Combine
import AppKit
import ServiceManagement
import UniformTypeIdentifiers

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
        static let appRules = "panevo.appRules"
        static let ignoredApps = "panevo.ignoredApps"
        static let displayBindings = "panevo.displayBindings"
        static let titleBarDoubleClick = "panevo.titleBarDoubleClick"
        static let modifierDrag = "panevo.modifierDrag"
        static let autoApplyDisplayProfiles = "panevo.autoApplyDisplayProfiles"
        static let hasCompletedOnboarding = "panevo.hasCompletedOnboarding"
        static let lastCheckedUpdateVersion = "panevo.lastCheckedUpdateVersion"
    }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published var shortcuts: [KeyboardShortcut] = []
    @Published var layoutProfiles: [LayoutProfile] = []
    @Published var appRules: [AppRule] = []
    @Published var ignoredBundleIdentifiers: [String] = []
    @Published var displayProfileBindings: [DisplayProfileBinding] = []

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

    @Published var titleBarDoubleClickEnabled: Bool {
        didSet { defaults.set(titleBarDoubleClickEnabled, forKey: Keys.titleBarDoubleClick) }
    }

    @Published var modifierDragEnabled: Bool {
        didSet { defaults.set(modifierDragEnabled, forKey: Keys.modifierDrag) }
    }

    @Published var autoApplyDisplayProfiles: Bool {
        didSet { defaults.set(autoApplyDisplayProfiles, forKey: Keys.autoApplyDisplayProfiles) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    private init() {
        let styleRaw = defaults.string(forKey: Keys.animationStyle) ?? SnapAnimationStyle.instant.rawValue
        animationStyle = SnapAnimationStyle(rawValue: styleRaw) ?? .instant
        showOverlay = defaults.object(forKey: Keys.showOverlay) as? Bool ?? true
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        windowGap = defaults.object(forKey: Keys.windowGap) as? Double ?? 0
        dragEdgeThreshold = defaults.object(forKey: Keys.dragEdgeThreshold) as? Double ?? 50
        titleBarDoubleClickEnabled = defaults.object(forKey: Keys.titleBarDoubleClick) as? Bool ?? true
        modifierDragEnabled = defaults.object(forKey: Keys.modifierDrag) as? Bool ?? true
        autoApplyDisplayProfiles = defaults.object(forKey: Keys.autoApplyDisplayProfiles) as? Bool ?? true
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)

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

        let existingActions = Set(shortcuts.map { $0.action })
        for action in SnapAction.allCases where !existingActions.contains(action) {
            shortcuts.append(KeyboardShortcut(action: action, keyCode: 0, modifiers: 0, isEnabled: false))
        }

        if let data = defaults.data(forKey: Keys.layoutProfiles),
           let saved = try? decoder.decode([LayoutProfile].self, from: data) {
            layoutProfiles = saved
        }

        if let data = defaults.data(forKey: Keys.appRules),
           let saved = try? decoder.decode([AppRule].self, from: data) {
            appRules = saved
        }

        ignoredBundleIdentifiers = defaults.stringArray(forKey: Keys.ignoredApps) ?? []

        if let data = defaults.data(forKey: Keys.displayBindings),
           let saved = try? decoder.decode([DisplayProfileBinding].self, from: data) {
            displayProfileBindings = saved
        }
    }

    func saveSettings() {
        persistShortcuts()
        persistLayoutProfiles()
        persistAppRules()
        persistIgnoredApps()
        persistDisplayBindings()
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

    private func persistAppRules() {
        if let data = try? encoder.encode(appRules) {
            defaults.set(data, forKey: Keys.appRules)
        }
    }

    private func persistIgnoredApps() {
        defaults.set(ignoredBundleIdentifiers, forKey: Keys.ignoredApps)
    }

    private func persistDisplayBindings() {
        if let data = try? encoder.encode(displayProfileBindings) {
            defaults.set(data, forKey: Keys.displayBindings)
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
        let existingActions = Set(shortcuts.map { $0.action })
        for action in SnapAction.allCases where !existingActions.contains(action) {
            shortcuts.append(KeyboardShortcut(action: action, keyCode: 0, modifiers: 0, isEnabled: false))
        }
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
        displayProfileBindings.removeAll { $0.layoutProfileID == profile.id }
        persistLayoutProfiles()
        persistDisplayBindings()
    }

    // MARK: - App Rules

    func saveAppRule(_ rule: AppRule) {
        if let index = appRules.firstIndex(where: { $0.id == rule.id }) {
            appRules[index] = rule
        } else {
            appRules.removeAll { $0.bundleIdentifier == rule.bundleIdentifier }
            appRules.append(rule)
        }
        persistAppRules()
    }

    func deleteAppRule(_ rule: AppRule) {
        appRules.removeAll { $0.id == rule.id }
        persistAppRules()
    }

    func rule(forBundleIdentifier bundleID: String) -> AppRule? {
        appRules.first { $0.isEnabled && $0.bundleIdentifier == bundleID }
    }

    // MARK: - Ignore List

    func addIgnoredApp(_ bundleID: String) {
        guard !bundleID.isEmpty, !ignoredBundleIdentifiers.contains(bundleID) else { return }
        ignoredBundleIdentifiers.append(bundleID)
        persistIgnoredApps()
    }

    func removeIgnoredApp(_ bundleID: String) {
        ignoredBundleIdentifiers.removeAll { $0 == bundleID }
        persistIgnoredApps()
    }

    func isIgnored(_ bundleID: String) -> Bool {
        ignoredBundleIdentifiers.contains(bundleID)
    }

    // MARK: - Display Profile Bindings

    func saveDisplayBinding(_ binding: DisplayProfileBinding) {
        if let index = displayProfileBindings.firstIndex(where: { $0.id == binding.id }) {
            displayProfileBindings[index] = binding
        } else {
            displayProfileBindings.removeAll { $0.displayCount == binding.displayCount }
            displayProfileBindings.append(binding)
        }
        persistDisplayBindings()
    }

    func deleteDisplayBinding(_ binding: DisplayProfileBinding) {
        displayProfileBindings.removeAll { $0.id == binding.id }
        persistDisplayBindings()
    }

    func binding(forDisplayCount count: Int) -> DisplayProfileBinding? {
        displayProfileBindings.first { $0.isEnabled && $0.displayCount == count }
    }

    // MARK: - Export / Import

    func makeExport() -> PanevoSettingsExport {
        PanevoSettingsExport(
            version: 1,
            shortcuts: shortcuts,
            layoutProfiles: layoutProfiles,
            appRules: appRules,
            ignoredBundleIdentifiers: ignoredBundleIdentifiers,
            displayProfileBindings: displayProfileBindings,
            animationStyle: animationStyle.rawValue,
            showOverlay: showOverlay,
            windowGap: windowGap,
            dragEdgeThreshold: dragEdgeThreshold,
            titleBarDoubleClickEnabled: titleBarDoubleClickEnabled,
            modifierDragEnabled: modifierDragEnabled,
            autoApplyDisplayProfiles: autoApplyDisplayProfiles
        )
    }

    func applyImport(_ exported: PanevoSettingsExport) {
        shortcuts = exported.shortcuts
        layoutProfiles = exported.layoutProfiles
        appRules = exported.appRules
        ignoredBundleIdentifiers = exported.ignoredBundleIdentifiers
        displayProfileBindings = exported.displayProfileBindings
        if let style = SnapAnimationStyle(rawValue: exported.animationStyle) {
            animationStyle = style
        }
        showOverlay = exported.showOverlay
        windowGap = exported.windowGap
        dragEdgeThreshold = exported.dragEdgeThreshold
        titleBarDoubleClickEnabled = exported.titleBarDoubleClickEnabled
        modifierDragEnabled = exported.modifierDragEnabled
        autoApplyDisplayProfiles = exported.autoApplyDisplayProfiles
        saveSettings()
        NotificationCenter.default.post(name: .panevoShortcutsChanged, object: nil)
    }

    @discardableResult
    func exportToFile() -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "panevo-settings.json"
        panel.title = NSLocalizedString("Export Settings", comment: "")

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(makeExport()) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func importFromFile() -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = NSLocalizedString("Import Settings", comment: "")

        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? Data(contentsOf: url),
              let exported = try? decoder.decode(PanevoSettingsExport.self, from: data) else {
            return false
        }

        applyImport(exported)
        return true
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
