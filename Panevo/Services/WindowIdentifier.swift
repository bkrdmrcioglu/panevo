import Foundation
import AppKit

class WindowIdentifier {
    static func getUniqueIdentifier(for element: AXUIElement, appBundleID: String) -> String? {
        var identifier = appBundleID

        if let windowTitle = AccessibilityManager.shared.getWindowTitle(from: element) {
            identifier.append("_\(windowTitle.hashValue)")
        }

        if let position = AccessibilityManager.shared.getWindowPosition(from: element) {
            identifier.append("_\(Int(position.x))_\(Int(position.y))")
        }

        return identifier.isEmpty ? nil : identifier
    }

    static func getFrontmostWindowInfo() -> (pid: pid_t, title: String)? {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return nil }

        let pid = frontmost.processIdentifier
        guard let element = AccessibilityManager.shared.getAccessibilityElement(for: pid) else { return nil }

        guard let windows = AccessibilityManager.shared.getAllWindows(from: element).first else { return nil }

        if let title = AccessibilityManager.shared.getWindowTitle(from: windows) {
            return (pid: pid, title: title)
        }

        return (pid: pid, title: "Unknown")
    }

    static func getWindowsForApplication(_ bundleID: String) -> [AXUIElement] {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else {
            return []
        }

        guard let element = AccessibilityManager.shared.getAccessibilityElement(for: app.processIdentifier) else {
            return []
        }

        return AccessibilityManager.shared.getAllWindows(from: element)
    }
}
