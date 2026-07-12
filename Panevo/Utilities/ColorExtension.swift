import SwiftUI

extension Color {
    static let panevoBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let panevoGray = Color(red: 0.94, green: 0.94, blue: 0.96)
    static let panevodarkGray = Color(red: 0.11, green: 0.11, blue: 0.12)

    static let success = Color(red: 0.34, green: 0.92, blue: 0.55)
    static let warning = Color(red: 1.0, green: 0.73, blue: 0.27)
    static let error = Color(red: 1.0, green: 0.27, blue: 0.27)
    static let info = Color(red: 0.0, green: 0.48, blue: 1.0)

    func withAlpha(_ alpha: Double) -> Color {
        var components = self.cgColor?.components ?? [0, 0, 0, 1]
        if components.count > 0 {
            components[components.count - 1] = alpha
        }

        if let color = self.cgColor {
            if let newColor = color.copy(alpha: alpha) {
                return Color(newColor)
            }
        }

        return self
    }

    var inverted: Color {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if os(macOS)
        NSColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        return Color(red: Double(1 - r), green: Double(1 - g), blue: Double(1 - b), opacity: Double(a))
    }
}

extension NSColor {
    func withAlpha(_ alpha: CGFloat) -> NSColor {
        return self.withAlphaComponent(alpha)
    }

    var swiftUIColor: Color {
        return Color(self)
    }
}
