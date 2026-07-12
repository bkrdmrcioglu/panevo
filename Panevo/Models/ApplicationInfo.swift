import Foundation
import AppKit

struct ApplicationInfo: Identifiable, Equatable {
    let id: String
    let bundleIdentifier: String
    let processIdentifier: pid_t
    let windowTitle: String
    let windowFrame: CGRect
    let isActive: Bool
    let applicationName: String

    var displayName: String {
        return applicationName.isEmpty ? bundleIdentifier : applicationName
    }

    static func == (lhs: ApplicationInfo, rhs: ApplicationInfo) -> Bool {
        return lhs.id == rhs.id && lhs.processIdentifier == rhs.processIdentifier
    }
}

struct DisplayInfo: Identifiable {
    let id: CGDirectDisplayID
    let frame: CGRect
    let visibleFrame: CGRect
    let name: String
    let isMain: Bool
    let isBuiltIn: Bool
    let width: CGFloat
    let height: CGFloat

    init(displayID: CGDirectDisplayID) {
        self.id = displayID
        self.isMain = displayID == CGMainDisplayID()
        self.isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

        var width: CGFloat = 0
        var height: CGFloat = 0
        let modeList = CGDisplayCopyAllDisplayModes(displayID, nil)
        if let modeList = modeList as? [CGDisplayMode] {
            if let currentMode = modeList.first {
                width = CGFloat(currentMode.width)
                height = CGFloat(currentMode.height)
            }
        }

        self.width = width
        self.height = height
        self.frame = CGDisplayBounds(displayID)
        self.visibleFrame = CGDisplayBounds(displayID)

        self.name = self.isBuiltIn ? "Built-in Display" : "External Display"
    }
}

enum SnapAnimationStyle: String, Codable {
    case smooth
    case snappy
    case springy
    case instant

    var duration: Double {
        switch self {
        case .smooth:
            return 0.3
        case .snappy:
            return 0.2
        case .springy:
            return 0.4
        case .instant:
            return 0.0
        }
    }
}

struct SnapOverlay {
    let targetFrame: CGRect
    let displayID: CGDirectDisplayID
    let animationStyle: SnapAnimationStyle
}
