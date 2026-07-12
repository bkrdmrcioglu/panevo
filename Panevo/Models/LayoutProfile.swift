import Foundation
import AppKit

struct LayoutProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var displayName: String
    var windowLayouts: [WindowLayoutSnapshot]
    var createdAt: Date
    var updatedAt: Date
    var isDefault: Bool

    init(name: String, displayName: String, windowLayouts: [WindowLayoutSnapshot]) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.windowLayouts = windowLayouts
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDefault = false
    }

    mutating func update(windowLayouts: [WindowLayoutSnapshot]) {
        self.windowLayouts = windowLayouts
        self.updatedAt = Date()
    }
}

struct WindowLayoutSnapshot: Codable, Equatable {
    let appBundleIdentifier: String
    let windowTitle: String
    let position: WindowPosition
    let displayID: CGDirectDisplayID
    // Exact window frame in Accessibility (top-left origin) coordinates.
    // Optional so profiles saved without it remain decodable.
    var frame: CGRect?

    init(appBundleIdentifier: String, windowTitle: String, position: WindowPosition, displayID: CGDirectDisplayID, frame: CGRect? = nil) {
        self.appBundleIdentifier = appBundleIdentifier
        self.windowTitle = windowTitle
        self.position = position
        self.displayID = displayID
        self.frame = frame
    }
}

enum PresetLayout: String, CaseIterable {
    case coding = "coding"
    case streaming = "streaming"
    case design = "design"
    case office = "office"

    var displayName: String {
        switch self {
        case .coding:
            return "Coding"
        case .streaming:
            return "Streaming"
        case .design:
            return "Design"
        case .office:
            return "Office"
        }
    }

    var description: String {
        switch self {
        case .coding:
            return "Editor on left, browser and terminal on right"
        case .streaming:
            return "Main window full screen with overlays"
        case .design:
            return "Design tool on main display, inspector on secondary"
        case .office:
            return "Document centered, references on sides"
        }
    }

    func createDefaultProfile() -> LayoutProfile {
        LayoutProfile(name: self.rawValue, displayName: self.displayName, windowLayouts: [])
    }
}
