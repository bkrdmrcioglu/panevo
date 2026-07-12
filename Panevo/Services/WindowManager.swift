import Foundation
import AppKit

class WindowManager {
    private let displayManager: DisplayManager
    private let accessibilityManager: AccessibilityManager
    private var dragMonitor: Any?
    private lazy var overlayManager = SnapOverlayManager(displayManager: displayManager)
    private var isDraggingNearEdge = false

    // Pre-snap frames so Restore can return windows to their original size.
    private var restoreFrames: [(window: AXUIElement, frame: CGRect)] = []

    // Drag tracking: only treat a drag as a window drag when the frontmost
    // window actually moves with the mouse.
    private var dragCandidateWindow: AXUIElement?
    private var dragStartOrigin: CGPoint?
    private var isWindowDrag = false

    init(displayManager: DisplayManager, accessibilityManager: AccessibilityManager) {
        self.displayManager = displayManager
        self.accessibilityManager = accessibilityManager
        setupDragMonitoring()
    }

    deinit {
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Window Snapping

    func snapWindow(to position: WindowPosition) {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let screen = NSScreen.main else { return }

        let resolved = cycledPosition(for: position, window: frontmostWindow, screen: screen)
        rememberFrameIfNeeded(frontmostWindow)
        let targetFrame = axFrame(from: resolved.getFrame(for: screen))
        moveWindow(frontmostWindow, to: targetFrame, animated: shouldAnimate)
    }

    func snapWindowToDisplay(_ displayID: CGDirectDisplayID, position: WindowPosition) {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let screen = NSScreen.screen(for: displayID) else { return }

        rememberFrameIfNeeded(frontmostWindow)
        let targetFrame = axFrame(from: position.getFrame(for: screen))
        moveWindow(frontmostWindow, to: targetFrame, animated: shouldAnimate)
    }

    // Pressing the same half-snap shortcut again cycles half → third → two thirds.
    private func cycledPosition(for position: WindowPosition, window: AXUIElement, screen: NSScreen) -> WindowPosition {
        let cycles: [WindowPosition: [WindowPosition]] = [
            .leftHalf: [.leftHalf, .thirdLeft, .twoThirdsLeft],
            .rightHalf: [.rightHalf, .thirdRight, .twoThirdsRight],
        ]

        guard let cycle = cycles[position],
              let currentPosition = accessibilityManager.getWindowPosition(from: window),
              let currentSize = accessibilityManager.getWindowSize(from: window) else {
            return position
        }

        let current = CGRect(origin: currentPosition, size: currentSize)

        for (index, candidate) in cycle.enumerated() {
            let frame = axFrame(from: candidate.getFrame(for: screen))
            if abs(frame.minX - current.minX) < 2, abs(frame.minY - current.minY) < 2,
               abs(frame.width - current.width) < 2, abs(frame.height - current.height) < 2 {
                return cycle[(index + 1) % cycle.count]
            }
        }
        return position
    }

    // MARK: - Restore

    private func rememberFrameIfNeeded(_ window: AXUIElement) {
        guard !restoreFrames.contains(where: { CFEqual($0.window, window) }),
              let position = accessibilityManager.getWindowPosition(from: window),
              let size = accessibilityManager.getWindowSize(from: window) else {
            return
        }

        restoreFrames.append((window, CGRect(origin: position, size: size)))
        if restoreFrames.count > 20 {
            restoreFrames.removeFirst()
        }
    }

    func restoreWindow() {
        guard let window = getFrontmostWindow(),
              let entry = restoreFrames.last(where: { CFEqual($0.window, window) }) else {
            return
        }

        moveWindow(window, to: entry.frame, animated: shouldAnimate)
        restoreFrames.removeAll { CFEqual($0.window, window) }
    }

    private var shouldAnimate: Bool {
        return SettingsManager.shared.animationStyle != .instant
    }

    // Cocoa coordinates have a bottom-left origin; the Accessibility API expects
    // a top-left origin relative to the primary screen.
    private func axFrame(from cocoaFrame: CGRect) -> CGRect {
        guard let primaryScreen = NSScreen.screens.first else { return cocoaFrame }
        let flippedY = primaryScreen.frame.maxY - cocoaFrame.maxY
        return CGRect(x: cocoaFrame.minX, y: flippedY, width: cocoaFrame.width, height: cocoaFrame.height)
    }

    func moveWindowToNextDisplay() {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let currentDisplay = getDisplayForWindow(frontmostWindow) else { return }
        guard let nextDisplay = displayManager.getNextDisplay(from: currentDisplay) else { return }

        moveWindowToDisplay(frontmostWindow, displayID: nextDisplay.id, preserveRelativePosition: true)
    }

    func moveWindowToPreviousDisplay() {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let currentDisplay = getDisplayForWindow(frontmostWindow) else { return }
        guard let previousDisplay = displayManager.getPreviousDisplay(from: currentDisplay) else { return }

        moveWindowToDisplay(frontmostWindow, displayID: previousDisplay.id, preserveRelativePosition: true)
    }

    // MARK: - Window Information

    func getFrontmostWindow() -> AXUIElement? {
        guard var pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }

        // When triggered from Panevo's own UI, target the window below ours
        // instead of snapping our own window.
        if pid == ProcessInfo.processInfo.processIdentifier {
            guard let otherPid = topmostOtherApplicationPid() else { return nil }
            pid = otherPid
        }

        guard let element = accessibilityManager.getAccessibilityElement(for: pid) else { return nil }

        if let focusedWindow = accessibilityManager.getFocusedWindow(from: element) {
            return focusedWindow
        }
        return accessibilityManager.getAllWindows(from: element).first
    }

    private func topmostOtherApplicationPid() -> pid_t? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let ownPid = ProcessInfo.processInfo.processIdentifier

        for info in windowList {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  pid != ownPid else {
                continue
            }
            return pid
        }
        return nil
    }

    func getAllWindows() -> [ApplicationInfo] {
        var applications: [ApplicationInfo] = []

        for workspace in NSWorkspace.shared.runningApplications {
            guard let element = accessibilityManager.getAccessibilityElement(for: workspace.processIdentifier) else { continue }

            let windows = accessibilityManager.getAllWindows(from: element)
            for window in windows {
                if let title = accessibilityManager.getWindowTitle(from: window),
                   let position = accessibilityManager.getWindowPosition(from: window),
                   let size = accessibilityManager.getWindowSize(from: window) {
                    let frame = CGRect(origin: position, size: size)
                    let appInfo = ApplicationInfo(
                        id: UUID().uuidString,
                        bundleIdentifier: workspace.bundleIdentifier ?? "",
                        processIdentifier: workspace.processIdentifier,
                        windowTitle: title,
                        windowFrame: frame,
                        isActive: workspace.isActive,
                        applicationName: workspace.localizedName ?? ""
                    )
                    applications.append(appInfo)
                }
            }
        }

        return applications
    }

    func getDisplayForWindow(_ window: AXUIElement) -> DisplayInfo? {
        guard let position = accessibilityManager.getWindowPosition(from: window),
              let size = accessibilityManager.getWindowSize(from: window) else {
            return nil
        }

        let frame = CGRect(origin: position, size: size)
        return displayManager.getDisplayContainingFrame(frame)
    }

    // MARK: - Private Methods

    private func moveWindow(_ window: AXUIElement, to frame: CGRect, animated: Bool) {
        if animated {
            animateWindow(window, to: frame)
        } else {
            _ = accessibilityManager.setWindowFrame(frame, for: window)
        }
    }

    private func moveWindowToDisplay(_ window: AXUIElement, displayID: CGDirectDisplayID, preserveRelativePosition: Bool) {
        guard let position = accessibilityManager.getWindowPosition(from: window),
              let size = accessibilityManager.getWindowSize(from: window),
              let currentDisplay = getDisplayForWindow(window) else {
            return
        }

        let targetScreen = NSScreen.screen(for: displayID)
        guard let targetScreen = targetScreen else { return }

        var newFrame = CGRect(origin: position, size: size)

        if preserveRelativePosition {
            let relativeX = (position.x - currentDisplay.frame.minX) / currentDisplay.frame.width
            let relativeY = (position.y - currentDisplay.frame.minY) / currentDisplay.frame.height

            newFrame.origin.x = targetScreen.frame.minX + (relativeX * targetScreen.frame.width)
            newFrame.origin.y = targetScreen.frame.minY + (relativeY * targetScreen.frame.height)
        } else {
            newFrame.origin.x = targetScreen.frame.minX + (targetScreen.frame.width - size.width) / 2
            newFrame.origin.y = targetScreen.frame.minY + (targetScreen.frame.height - size.height) / 2
        }

        moveWindow(window, to: newFrame, animated: true)
    }

    private func animateWindow(_ window: AXUIElement, to targetFrame: CGRect) {
        guard let currentPosition = accessibilityManager.getWindowPosition(from: window),
              let currentSize = accessibilityManager.getWindowSize(from: window) else {
            return
        }

        let steps = 10
        let duration = max(SettingsManager.shared.animationStyle.duration, 0.1)
        let stepDuration = duration / Double(steps)

        let currentFrame = CGRect(origin: currentPosition, size: currentSize)

        for step in 1...steps {
            let progress = CGFloat(step) / CGFloat(steps)

            let newX = currentFrame.origin.x + (targetFrame.origin.x - currentFrame.origin.x) * progress
            let newY = currentFrame.origin.y + (targetFrame.origin.y - currentFrame.origin.y) * progress
            let newWidth = currentFrame.size.width + (targetFrame.size.width - currentFrame.size.width) * progress
            let newHeight = currentFrame.size.height + (targetFrame.size.height - currentFrame.size.height) * progress

            let newFrame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)

            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                _ = self.accessibilityManager.setWindowFrame(newFrame, for: window)
            }
        }
    }

    private func setupDragMonitoring() {
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handleDragEvent(event)
        }
    }

    private func handleDragEvent(_ event: NSEvent) {
        let mouseLocation = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDragged:
            trackWindowDrag()
            if isWindowDrag {
                updateDragOverlay(at: mouseLocation)
            }
        case .leftMouseUp:
            hideDragOverlay()
            if isWindowDrag {
                handleDragRelease(at: mouseLocation)
            }
            resetDragTracking()
        default:
            break
        }
    }

    private func trackWindowDrag() {
        if dragCandidateWindow == nil {
            dragCandidateWindow = getFrontmostWindow()
            if let window = dragCandidateWindow {
                dragStartOrigin = accessibilityManager.getWindowPosition(from: window)
            }
            return
        }

        guard !isWindowDrag,
              let window = dragCandidateWindow,
              let startOrigin = dragStartOrigin,
              let currentOrigin = accessibilityManager.getWindowPosition(from: window) else {
            return
        }

        // The window only moves with the cursor when its title bar is being dragged.
        if abs(currentOrigin.x - startOrigin.x) > 5 || abs(currentOrigin.y - startOrigin.y) > 5 {
            isWindowDrag = true
        }
    }

    private func resetDragTracking() {
        dragCandidateWindow = nil
        dragStartOrigin = nil
        isWindowDrag = false
    }

    private func screenUnderMouse(_ point: CGPoint) -> NSScreen? {
        return NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }

    private func edgePosition(at point: CGPoint) -> (position: WindowPosition, displayID: CGDirectDisplayID)? {
        guard let screen = screenUnderMouse(point) else { return nil }

        let screenFrame = screen.visibleFrame
        let threshold: CGFloat = 50

        let position: WindowPosition?
        if point.x - screenFrame.minX < threshold {
            position = .leftHalf
        } else if screenFrame.maxX - point.x < threshold {
            position = .rightHalf
        } else if screenFrame.maxY - point.y < threshold {
            position = .topHalf
        } else if point.y - screenFrame.minY < threshold {
            position = .bottomHalf
        } else {
            position = nil
        }

        guard let position = position else { return nil }
        return (position, screen.displayID)
    }

    private func updateDragOverlay(at point: CGPoint) {
        guard SettingsManager.shared.showOverlay else { return }

        if let edge = edgePosition(at: point) {
            if !isDraggingNearEdge {
                isDraggingNearEdge = true
                overlayManager.showOverlay(for: edge.position, on: edge.displayID)
            } else {
                overlayManager.updateOverlayPosition(for: edge.position, on: edge.displayID)
            }
        } else if isDraggingNearEdge {
            isDraggingNearEdge = false
            overlayManager.hideAllOverlays()
        }
    }

    private func hideDragOverlay() {
        if isDraggingNearEdge {
            isDraggingNearEdge = false
            overlayManager.hideAllOverlays()
        }
    }

    private func handleDragRelease(at point: CGPoint) {
        if let edge = edgePosition(at: point) {
            snapWindowToDisplay(edge.displayID, position: edge.position)
        }
    }
}
