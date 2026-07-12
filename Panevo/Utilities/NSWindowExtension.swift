import Foundation
import AppKit

extension NSWindow {
    func snapToPosition(_ position: WindowPosition) {
        guard let screen = self.screen else { return }

        let targetFrame = position.getFrame(for: screen)
        self.setFrame(targetFrame, display: true, animate: true)
    }

    func moveToDisplay(_ displayID: CGDirectDisplayID) {
        guard let screen = NSScreen.screen(for: displayID) else { return }

        let visibleFrame = screen.visibleFrame
        let newOrigin = CGPoint(
            x: visibleFrame.minX + (visibleFrame.width - self.frame.width) / 2,
            y: visibleFrame.minY + (visibleFrame.height - self.frame.height) / 2
        )

        self.setFrameOrigin(newOrigin)
    }

    func centerOnScreen() {
        guard let screen = self.screen else { return }

        let visibleFrame = screen.visibleFrame
        let newOrigin = CGPoint(
            x: visibleFrame.minX + (visibleFrame.width - self.frame.width) / 2,
            y: visibleFrame.minY + (visibleFrame.height - self.frame.height) / 2
        )

        self.setFrameOrigin(newOrigin)
    }

    func constrainToScreen() {
        guard let screen = self.screen else { return }

        let visibleFrame = screen.visibleFrame
        var newFrame = self.frame

        if newFrame.origin.x < visibleFrame.minX {
            newFrame.origin.x = visibleFrame.minX
        }
        if newFrame.origin.y < visibleFrame.minY {
            newFrame.origin.y = visibleFrame.minY
        }

        if newFrame.maxX > visibleFrame.maxX {
            newFrame.size.width = visibleFrame.maxX - newFrame.origin.x
        }
        if newFrame.maxY > visibleFrame.maxY {
            newFrame.size.height = visibleFrame.maxY - newFrame.origin.y
        }

        self.setFrame(newFrame, display: true)
    }

    func setFrameWithAnimation(_ frame: CGRect, duration: TimeInterval = 0.3) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(frame, display: true)
        }
    }
}

extension NSApplication {
    func hideAllWindowsExcept(_ window: NSWindow) {
        for candidateWindow in self.windows {
            if candidateWindow != window {
                candidateWindow.orderOut(self)
            }
        }
    }
}
