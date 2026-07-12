import Foundation
import AppKit

extension CGRect {
    func clampedToScreen() -> CGRect {
        guard let screen = NSScreen.main else { return self }
        let frame = screen.visibleFrame

        var clampedRect = self

        if clampedRect.origin.x < frame.minX {
            clampedRect.origin.x = frame.minX
        }
        if clampedRect.origin.y < frame.minY {
            clampedRect.origin.y = frame.minY
        }

        if clampedRect.maxX > frame.maxX {
            clampedRect.size.width = frame.maxX - clampedRect.origin.x
        }
        if clampedRect.maxY > frame.maxY {
            clampedRect.size.height = frame.maxY - clampedRect.origin.y
        }

        return clampedRect
    }

    func intersects(with other: CGRect) -> Bool {
        return !self.intersection(other).isEmpty
    }

    func containsPoint(_ point: CGPoint, with tolerance: CGFloat = 0) -> Bool {
        return point.x >= minX - tolerance && point.x <= maxX + tolerance &&
               point.y >= minY - tolerance && point.y <= maxY + tolerance
    }

    func distance(to point: CGPoint) -> CGFloat {
        let rect = self
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return sqrt(dx * dx + dy * dy)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }

    static func screen(for cgDirectDisplayID: CGDirectDisplayID) -> NSScreen? {
        return NSScreen.screens.first(where: { $0.displayID == cgDirectDisplayID })
    }

    func getWindowPosition(_ point: CGPoint) -> WindowPosition? {
        let visibleFrame = self.visibleFrame
        let width = visibleFrame.width
        let height = visibleFrame.height
        let centerX = visibleFrame.midX
        let centerY = visibleFrame.midY

        let thresholdX = width * 0.3
        let thresholdY = height * 0.3

        let isLeft = point.x - visibleFrame.minX < thresholdX
        let isRight = visibleFrame.maxX - point.x < thresholdX
        let isTop = visibleFrame.maxY - point.y < thresholdY
        let isBottom = point.y - visibleFrame.minY < thresholdY

        if isLeft && isTop {
            return .topLeft
        } else if isRight && isTop {
            return .topRight
        } else if isLeft && isBottom {
            return .bottomLeft
        } else if isRight && isBottom {
            return .bottomRight
        } else if isLeft {
            return .leftHalf
        } else if isRight {
            return .rightHalf
        } else if isTop {
            return .topHalf
        } else if isBottom {
            return .bottomHalf
        }

        return nil
    }
}

extension CGSize {
    func scaled(by scale: CGFloat) -> CGSize {
        return CGSize(width: width * scale, height: height * scale)
    }

    func aspectRatio() -> CGFloat {
        return width / height
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return sqrt(dx * dx + dy * dy)
    }

    func midPoint(with point: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x + point.x) / 2, y: (self.y + point.y) / 2)
    }

    func offset(by offset: CGSize) -> CGPoint {
        return CGPoint(x: self.x + offset.width, y: self.y + offset.height)
    }
}
