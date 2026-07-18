import Foundation

/// Snaps a window to a fixed position whenever that app becomes frontmost.
struct AppRule: Identifiable, Codable, Equatable {
    let id: UUID
    var bundleIdentifier: String
    var applicationName: String
    var position: WindowPosition
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        applicationName: String,
        position: WindowPosition,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.position = position
        self.isEnabled = isEnabled
    }
}

/// Binds a saved layout profile to a display-count signature (e.g. laptop dock/undock).
struct DisplayProfileBinding: Identifiable, Codable, Equatable {
    let id: UUID
    /// Number of active displays this binding matches.
    var displayCount: Int
    var layoutProfileID: UUID
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        displayCount: Int,
        layoutProfileID: UUID,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.displayCount = displayCount
        self.layoutProfileID = layoutProfileID
        self.isEnabled = isEnabled
    }
}

/// Serializable settings bundle for export / import.
struct PanevoSettingsExport: Codable {
    var version: Int
    var shortcuts: [KeyboardShortcut]
    var layoutProfiles: [LayoutProfile]
    var appRules: [AppRule]
    var ignoredBundleIdentifiers: [String]
    var displayProfileBindings: [DisplayProfileBinding]
    var animationStyle: String
    var showOverlay: Bool
    var windowGap: Double
    var dragEdgeThreshold: Double
    var titleBarDoubleClickEnabled: Bool
    var modifierDragEnabled: Bool
    var autoApplyDisplayProfiles: Bool
}
