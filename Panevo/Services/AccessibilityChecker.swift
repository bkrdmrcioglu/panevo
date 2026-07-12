import Foundation
import AppKit
import os.log

class AccessibilityChecker {
    static let shared = AccessibilityChecker()

    private let osLog = OSLog(subsystem: "com.panevo.accessibility", category: "checker")

    private init() {}

    func checkAccessibilityStatus() -> AccessibilityStatus {
        let isEnabled = AXIsProcessTrusted()

        if isEnabled {
            return .granted
        } else {
            return .denied
        }
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func canControlWindow(_ element: AXUIElement) -> Bool {
        var resizable: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &resizable)
        return result == .success
    }

    func validateWindowElement(_ element: AXUIElement) -> Bool {
        var title: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
        return result == .success
    }

    func getApplicationName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        let bundle = Bundle(url: url)
        return bundle?.infoDictionary?["CFBundleName"] as? String
    }

    func checkPermissionStatus() {
        let status = checkAccessibilityStatus()
        os_log("Accessibility status: %{public}@", log: osLog, type: .info, status.description)
    }

    func logWindowInfo(_ element: AXUIElement, title: String) {
        if let position = AccessibilityManager.shared.getWindowPosition(from: element),
           let size = AccessibilityManager.shared.getWindowSize(from: element) {
            os_log("Window '%{public}@' at (%.0f, %.0f) size %.0f×%.0f",
                   log: osLog, type: .debug, title, position.x, position.y, size.width, size.height)
        }
    }
}

enum AccessibilityStatus: CustomStringConvertible {
    case granted
    case denied

    var description: String {
        switch self {
        case .granted:
            return "Accessibility permission granted"
        case .denied:
            return "Accessibility permission denied"
        }
    }

    var isGranted: Bool {
        return self == .granted
    }
}
