import Foundation
import AppKit

extension CGDirectDisplayID {
    var screen: NSScreen? {
        return NSScreen.screen(for: self)
    }

    var bounds: CGRect {
        return CGDisplayBounds(self)
    }

    var visibleFrame: CGRect {
        return self.screen?.visibleFrame ?? self.bounds
    }

    var width: CGFloat {
        return self.bounds.width
    }

    var height: CGFloat {
        return self.bounds.height
    }

    var isBuiltIn: Bool {
        return CGDisplayIsBuiltin(self) != 0
    }

    var isMain: Bool {
        return self == CGMainDisplayID()
    }

    var name: String {
        return isBuiltIn ? "Built-in Display" : "External Display"
    }
}
