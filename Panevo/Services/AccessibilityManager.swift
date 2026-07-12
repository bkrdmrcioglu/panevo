import Foundation
import AppKit

class AccessibilityManager {
    static let shared = AccessibilityManager()

    private init() {}

    var isAccessibilityEnabled: Bool {
        return AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        guard !isAccessibilityEnabled else { return }

        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func getAccessibilityElement(for pid: pid_t) -> AXUIElement? {
        return AXUIElementCreateApplication(pid)
    }

    func getWindowElement(from element: AXUIElement, at index: Int) -> AXUIElement? {
        var windows: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windows)

        guard result == .success, let windowList = windows as? [AXUIElement], windowList.count > index else {
            return nil
        }

        return windowList[index]
    }

    func getAllWindows(from element: AXUIElement) -> [AXUIElement] {
        var windows: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windows)

        guard result == .success, let windowList = windows as? [AXUIElement] else {
            return []
        }

        return windowList
    }

    func getWindowTitle(from element: AXUIElement) -> String? {
        var title: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
        return result == .success ? title as? String : nil
    }

    func getWindowPosition(from element: AXUIElement) -> CGPoint? {
        var position: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)

        guard result == .success, let value = position, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        var point = CGPoint.zero
        AXValueGetValue(value as! AXValue, .cgPoint, &point)
        return point
    }

    func getWindowSize(from element: AXUIElement) -> CGSize? {
        var size: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size)

        guard result == .success, let value = size, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        var cgSize = CGSize.zero
        AXValueGetValue(value as! AXValue, .cgSize, &cgSize)
        return cgSize
    }

    func getFocusedWindow(from element: AXUIElement) -> AXUIElement? {
        var window: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &window)

        guard result == .success, let value = window, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return (value as! AXUIElement)
    }

    func setWindowPosition(_ position: CGPoint, for element: AXUIElement) -> Bool {
        var mutablePosition = position
        let positionValue = AXValueCreate(.cgPoint, &mutablePosition)!
        let result = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue)
        return result == .success
    }

    func setWindowSize(_ size: CGSize, for element: AXUIElement) -> Bool {
        var mutableSize = size
        let sizeValue = AXValueCreate(.cgSize, &mutableSize)!
        let result = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        return result == .success
    }

    func setWindowFrame(_ frame: CGRect, for element: AXUIElement) -> Bool {
        let positionResult = setWindowPosition(frame.origin, for: element)
        let sizeResult = setWindowSize(frame.size, for: element)
        return positionResult && sizeResult
    }

    func isWindowResizable(from element: AXUIElement) -> Bool {
        var resizable: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &resizable)
        return result == .success
    }

    func focusWindow(_ element: AXUIElement) -> Bool {
        var focusedWindow: AnyObject?
        let result = AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        return result == .success
    }
}
