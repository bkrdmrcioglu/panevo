import AppKit
import SwiftUI

class SnapOverlayWindow: NSWindow {
    private let overlayView = SnapOverlayView()

    init(frame: CGRect) {
        super.init(contentRect: frame, styleMask: [], backing: .buffered, defer: false)

        self.level = .screenSaver
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .transient]

        self.contentView = overlayView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showOverlay(for frame: CGRect) {
        self.setFrame(frame, display: true)
        self.orderFront(nil)
        overlayView.animateIn()
    }

    func hideOverlay() {
        overlayView.animateOut {
            self.orderOut(nil)
        }
    }

    func updateOverlayFrame(_ frame: CGRect) {
        self.setFrame(frame, display: true)
    }
}

class SnapOverlayView: NSView {
    private let cornerRadius: CGFloat = 12
    private let borderWidth: CGFloat = 2
    private let animationDuration: TimeInterval = 0.2

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let path = NSBezierPath(roundedRect: self.bounds, xRadius: cornerRadius, yRadius: cornerRadius)

        NSColor.blue.withAlphaComponent(0.1).setFill()
        path.fill()

        NSColor.blue.withAlphaComponent(0.5).setStroke()
        path.lineWidth = borderWidth
        path.stroke()
    }

    func animateIn() {
        self.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0.0
        }, completionHandler: completion)
    }
}

class SnapOverlayManager {
    private var overlayWindows: [SnapOverlayWindow] = []
    private let displayManager: DisplayManager

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }

    func showOverlay(for position: WindowPosition, on displayID: CGDirectDisplayID) {
        guard let screen = NSScreen.screen(for: displayID) else { return }

        let targetFrame = position.getFrame(for: screen)

        if let existing = overlayWindows.first {
            existing.updateOverlayFrame(targetFrame)
            existing.showOverlay(for: targetFrame)
        } else {
            let overlay = SnapOverlayWindow(frame: targetFrame)
            overlay.showOverlay(for: targetFrame)
            overlayWindows.append(overlay)
        }
    }

    func hideAllOverlays() {
        for overlay in overlayWindows {
            overlay.hideOverlay()
        }
        overlayWindows.removeAll()
    }

    func updateOverlayPosition(for position: WindowPosition?, on displayID: CGDirectDisplayID) {
        guard let position = position else {
            hideAllOverlays()
            return
        }

        showOverlay(for: position, on: displayID)
    }
}
