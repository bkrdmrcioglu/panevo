import Foundation

struct AppConfiguration {
    static let appName = "Panevo"
    static let appVersion = "1.0"
    static let appBuildNumber = "1"
    static let appBundle = "com.panevo.app"

    static let minMacOSVersion = "14.0"
    static let supportedLanguages = ["en", "tr"]

    static let defaultSnapAnimationDuration: TimeInterval = 0.3
    static let defaultSnapSensitivity: CGFloat = 50
    static let defaultDragSnapThreshold: CGFloat = 50

    static let menuBarIconSize = NSSize(width: 18, height: 18)

    static let preferencesWindowSize = NSSize(width: 600, height: 500)
    static let minimumWindowSize = NSSize(width: 700, height: 600)

    static let defaultKeyboardShortcuts: [String: String] = [
        "leftHalf": "⌘⌥←",
        "rightHalf": "⌘⌥→",
        "topHalf": "⌘⌥↑",
        "bottomHalf": "⌘⌥↓",
        "fullScreen": "⌘⌥F",
        "center": "⌘⌥C",
    ]

    static let accessibilityPermissionKey = "NSAccessibilityPermission"
    static let launchAtLoginKey = "launchAtLogin"

    struct URLs {
        static let supportURL = URL(string: "https://panevo.app/support")
        static let feedbackURL = URL(string: "https://panevo.app/feedback")
        static let documentationURL = URL(string: "https://panevo.app/docs")
    }
}
