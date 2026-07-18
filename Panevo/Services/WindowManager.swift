import Foundation
import AppKit
import Carbon

class WindowManager {
    private let displayManager: DisplayManager
    private let accessibilityManager: AccessibilityManager
    private var dragMonitor: Any?
    private var clickMonitor: Any?
    private lazy var overlayManager = SnapOverlayManager(displayManager: displayManager)
    private lazy var paletteManager = SnapPaletteManager(
        displayManager: displayManager,
        onSelect: { [weak self] position, displayID in
            self?.snapWindowToDisplay(displayID, position: position)
        }
    )
    private var isDraggingNearEdge = false

    // Pre-snap frames so Restore can return windows to their original size.
    private var restoreFrames: [(window: AXUIElement, frame: CGRect)] = []

    // Global undo stack of previous frames (last snap action).
    private var undoStack: [(window: AXUIElement, frame: CGRect)] = []

    // Drag tracking
    private var dragCandidateWindow: AXUIElement?
    private var dragStartOrigin: CGPoint?
    private var isWindowDrag = false
    private var isModifierPaletteDrag = false

    // App rules
    private var appActivationObserver: NSObjectProtocol?
    private var lastRuledBundleID: String?

    init(displayManager: DisplayManager, accessibilityManager: AccessibilityManager) {
        self.displayManager = displayManager
        self.accessibilityManager = accessibilityManager
        setupDragMonitoring()
        setupTitleBarDoubleClick()
        setupAppRuleObserver()
    }

    deinit {
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let observer = appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - Window Snapping

    func snapWindow(to position: WindowPosition) {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let screen = NSScreen.main else { return }
        guard !isFrontmostIgnored() else { return }

        let resolved = cycledPosition(for: position, window: frontmostWindow, screen: screen)
        pushUndo(for: frontmostWindow)
        rememberFrameIfNeeded(frontmostWindow)
        moveWindow(frontmostWindow, to: targetFrame(for: resolved, on: screen), animated: shouldAnimate)
    }

    func snapWindowToDisplay(_ displayID: CGDirectDisplayID, position: WindowPosition) {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let screen = NSScreen.screen(for: displayID) else { return }
        guard !isFrontmostIgnored() else { return }

        pushUndo(for: frontmostWindow)
        rememberFrameIfNeeded(frontmostWindow)
        moveWindow(frontmostWindow, to: targetFrame(for: position, on: screen), animated: shouldAnimate)
    }

    private func targetFrame(for position: WindowPosition, on screen: NSScreen) -> CGRect {
        var frame = position.getFrame(for: screen)
        let gap = CGFloat(SettingsManager.shared.windowGap)
        if gap > 0 {
            frame = frame.insetBy(dx: gap / 2, dy: gap / 2)
        }
        return axFrame(from: frame)
    }

    private func cycledPosition(for position: WindowPosition, window: AXUIElement, screen: NSScreen) -> WindowPosition {
        let cycles: [WindowPosition: [WindowPosition]] = [
            .leftHalf: [.leftHalf, .thirdLeft, .twoThirdsLeft, .leftTwoFifths, .leftThreeFifths],
            .rightHalf: [.rightHalf, .thirdRight, .twoThirdsRight, .rightThreeFifths, .rightTwoFifths],
        ]

        guard let cycle = cycles[position],
              let currentPosition = accessibilityManager.getWindowPosition(from: window),
              let currentSize = accessibilityManager.getWindowSize(from: window) else {
            return position
        }

        let current = CGRect(origin: currentPosition, size: currentSize)

        for (index, candidate) in cycle.enumerated() {
            let frame = targetFrame(for: candidate, on: screen)
            if abs(frame.minX - current.minX) < 2, abs(frame.minY - current.minY) < 2,
               abs(frame.width - current.width) < 2, abs(frame.height - current.height) < 2 {
                return cycle[(index + 1) % cycle.count]
            }
        }
        return position
    }

    // MARK: - Undo / Restore

    private func pushUndo(for window: AXUIElement) {
        guard let position = accessibilityManager.getWindowPosition(from: window),
              let size = accessibilityManager.getWindowSize(from: window) else {
            return
        }
        undoStack.append((window, CGRect(origin: position, size: size)))
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    func undoLastSnap() {
        guard let entry = undoStack.popLast() else { return }
        moveWindow(entry.window, to: entry.frame, animated: shouldAnimate)
    }

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

        pushUndo(for: window)
        moveWindow(window, to: entry.frame, animated: shouldAnimate)
        restoreFrames.removeAll { CFEqual($0.window, window) }
    }

    // MARK: - Tile All

    func tileAllWindows() {
        guard let screen = NSScreen.main else { return }
        let ownPid = ProcessInfo.processInfo.processIdentifier
        var windows: [AXUIElement] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  app.processIdentifier != ownPid,
                  let bundleID = app.bundleIdentifier,
                  !SettingsManager.shared.isIgnored(bundleID),
                  let element = accessibilityManager.getAccessibilityElement(for: app.processIdentifier) else {
                continue
            }
            for window in accessibilityManager.getAllWindows(from: element) {
                if accessibilityManager.getWindowTitle(from: window) != nil {
                    windows.append(window)
                }
            }
        }

        guard !windows.isEmpty else { return }

        let count = windows.count
        let columns = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        let visible = screen.visibleFrame
        let gap = CGFloat(SettingsManager.shared.windowGap)
        let cellWidth = (visible.width - gap * CGFloat(columns + 1)) / CGFloat(columns)
        let cellHeight = (visible.height - gap * CGFloat(rows + 1)) / CGFloat(rows)

        for (index, window) in windows.enumerated() {
            let col = index % columns
            let row = index / columns
            let cocoa = CGRect(
                x: visible.minX + gap + CGFloat(col) * (cellWidth + gap),
                y: visible.minY + gap + CGFloat(rows - 1 - row) * (cellHeight + gap),
                width: cellWidth,
                height: cellHeight
            )
            pushUndo(for: window)
            rememberFrameIfNeeded(window)
            moveWindow(window, to: axFrame(from: cocoa), animated: shouldAnimate)
        }
    }

    // MARK: - Snap Palette

    func showSnapPalette() {
        guard let screen = NSScreen.main else { return }
        paletteManager.show(on: screen)
    }

    func hideSnapPalette() {
        paletteManager.hide()
    }

    private var shouldAnimate: Bool {
        return SettingsManager.shared.animationStyle != .instant
    }

    private func axFrame(from cocoaFrame: CGRect) -> CGRect {
        guard let primaryScreen = NSScreen.screens.first else { return cocoaFrame }
        let flippedY = primaryScreen.frame.maxY - cocoaFrame.maxY
        return CGRect(x: cocoaFrame.minX, y: flippedY, width: cocoaFrame.width, height: cocoaFrame.height)
    }

    func moveWindowToNextDisplay() {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let currentDisplay = getDisplayForWindow(frontmostWindow) else { return }
        guard let nextDisplay = displayManager.getNextDisplay(from: currentDisplay) else { return }

        pushUndo(for: frontmostWindow)
        moveWindowToDisplay(frontmostWindow, displayID: nextDisplay.id, preserveRelativePosition: true)
    }

    func moveWindowToPreviousDisplay() {
        guard let frontmostWindow = getFrontmostWindow() else { return }
        guard let currentDisplay = getDisplayForWindow(frontmostWindow) else { return }
        guard let previousDisplay = displayManager.getPreviousDisplay(from: currentDisplay) else { return }

        pushUndo(for: frontmostWindow)
        moveWindowToDisplay(frontmostWindow, displayID: previousDisplay.id, preserveRelativePosition: true)
    }

    // MARK: - Window Information

    func getFrontmostWindow() -> AXUIElement? {
        guard var pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }

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

    private func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func isFrontmostIgnored() -> Bool {
        guard let bundleID = frontmostBundleID() else { return false }
        return SettingsManager.shared.isIgnored(bundleID)
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

    // MARK: - App Rules

    private func setupAppRuleObserver() {
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
    }

    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier,
              bundleID != Bundle.main.identifierString else {
            return
        }

        guard let rule = SettingsManager.shared.rule(forBundleIdentifier: bundleID) else {
            lastRuledBundleID = nil
            return
        }

        // Avoid re-snapping the same app repeatedly while switching within it.
        if lastRuledBundleID == bundleID { return }
        lastRuledBundleID = bundleID

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.snapWindow(to: rule.position)
        }
    }

    // MARK: - Title Bar Double Click

    private func setupTitleBarDoubleClick() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard SettingsManager.shared.titleBarDoubleClickEnabled,
                  event.clickCount == 2 else { return }
            self?.handleTitleBarDoubleClick(at: NSEvent.mouseLocation)
        }
    }

    private func handleTitleBarDoubleClick(at point: CGPoint) {
        guard !isFrontmostIgnored(),
              let window = getFrontmostWindow(),
              let axOrigin = accessibilityManager.getWindowPosition(from: window),
              let axSize = accessibilityManager.getWindowSize(from: window),
              let primary = NSScreen.screens.first else {
            return
        }

        // Convert AX (top-left) to Cocoa (bottom-left) for hit testing.
        let cocoaY = primary.frame.maxY - axOrigin.y - axSize.height
        let cocoaFrame = CGRect(x: axOrigin.x, y: cocoaY, width: axSize.width, height: axSize.height)
        let titleBarHeight: CGFloat = 28
        let titleBar = CGRect(
            x: cocoaFrame.minX,
            y: cocoaFrame.maxY - titleBarHeight,
            width: cocoaFrame.width,
            height: titleBarHeight
        )

        guard titleBar.contains(point) else { return }
        snapWindow(to: .fullScreen)
    }

    // MARK: - Private move helpers

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

    // MARK: - Drag Monitoring

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
                if SettingsManager.shared.modifierDragEnabled && isControlOptionHeld(event) {
                    isModifierPaletteDrag = true
                    updateModifierPalette(at: mouseLocation)
                } else {
                    updateDragOverlay(at: mouseLocation)
                }
            }
        case .leftMouseUp:
            if isModifierPaletteDrag {
                paletteManager.selectAt(mouseLocation)
                paletteManager.hide()
                isModifierPaletteDrag = false
            } else {
                hideDragOverlay()
                if isWindowDrag {
                    handleDragRelease(at: mouseLocation)
                }
            }
            resetDragTracking()
        default:
            break
        }
    }

    private func isControlOptionHeld(_ event: NSEvent) -> Bool {
        event.modifierFlags.contains(.control) && event.modifierFlags.contains(.option)
    }

    private func updateModifierPalette(at point: CGPoint) {
        guard let screen = screenUnderMouse(point) else { return }
        paletteManager.show(on: screen)
        paletteManager.highlightAt(point)
    }

    private func trackWindowDrag() {
        if isFrontmostIgnored() {
            resetDragTracking()
            return
        }

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
        let threshold = CGFloat(SettingsManager.shared.dragEdgeThreshold)

        let nearLeft = point.x - screenFrame.minX < threshold
        let nearRight = screenFrame.maxX - point.x < threshold
        let nearTop = screenFrame.maxY - point.y < threshold
        let nearBottom = point.y - screenFrame.minY < threshold

        let position: WindowPosition?
        switch (nearLeft, nearRight, nearTop, nearBottom) {
        case (true, _, true, _): position = .topLeft
        case (true, _, _, true): position = .bottomLeft
        case (_, true, true, _): position = .topRight
        case (_, true, _, true): position = .bottomRight
        case (true, _, _, _): position = .leftHalf
        case (_, true, _, _): position = .rightHalf
        case (_, _, true, _): position = .topHalf
        case (_, _, _, true): position = .bottomHalf
        default: position = nil
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
