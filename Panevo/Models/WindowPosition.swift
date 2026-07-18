import Foundation
import AppKit

enum WindowPosition: String, Codable, CaseIterable {
    case leftHalf = "leftHalf"
    case rightHalf = "rightHalf"
    case topHalf = "topHalf"
    case bottomHalf = "bottomHalf"
    case fullScreen = "fullScreen"
    case center = "center"
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    case thirdLeft = "thirdLeft"
    case thirdCenter = "thirdCenter"
    case thirdRight = "thirdRight"
    case twoThirdsLeft = "twoThirdsLeft"
    case twoThirdsRight = "twoThirdsRight"

    // Sixths (3×2 grid)
    case topLeftSixth = "topLeftSixth"
    case topCenterSixth = "topCenterSixth"
    case topRightSixth = "topRightSixth"
    case bottomLeftSixth = "bottomLeftSixth"
    case bottomCenterSixth = "bottomCenterSixth"
    case bottomRightSixth = "bottomRightSixth"

    // Custom ratios
    case leftTwoFifths = "leftTwoFifths"       // 40%
    case rightThreeFifths = "rightThreeFifths" // 60%
    case leftThreeFifths = "leftThreeFifths"   // 60%
    case rightTwoFifths = "rightTwoFifths"     // 40%
    case almostMaximize = "almostMaximize"

    var displayName: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .fullScreen: return "Full Screen"
        case .center: return "Center"
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .thirdLeft: return "Left Third"
        case .thirdCenter: return "Center Third"
        case .thirdRight: return "Right Third"
        case .twoThirdsLeft: return "Two Thirds Left"
        case .twoThirdsRight: return "Two Thirds Right"
        case .topLeftSixth: return "Top Left Sixth"
        case .topCenterSixth: return "Top Center Sixth"
        case .topRightSixth: return "Top Right Sixth"
        case .bottomLeftSixth: return "Bottom Left Sixth"
        case .bottomCenterSixth: return "Bottom Center Sixth"
        case .bottomRightSixth: return "Bottom Right Sixth"
        case .leftTwoFifths: return "Left 40%"
        case .rightThreeFifths: return "Right 60%"
        case .leftThreeFifths: return "Left 60%"
        case .rightTwoFifths: return "Right 40%"
        case .almostMaximize: return "Almost Maximize"
        }
    }

    var symbolName: String {
        switch self {
        case .leftHalf, .rightHalf:
            return "rectangle.split.2.vertical"
        case .topHalf, .bottomHalf:
            return "rectangle.split.2.horizontal"
        case .fullScreen, .almostMaximize:
            return "rectangle"
        case .center:
            return "square"
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return "square.grid.2x2"
        case .thirdLeft, .thirdCenter, .thirdRight, .twoThirdsLeft, .twoThirdsRight:
            return "rectangle.split.3.vertical"
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return "rectangle.split.3x3"
        case .leftTwoFifths, .rightThreeFifths, .leftThreeFifths, .rightTwoFifths:
            return "rectangle.split.2x1"
        }
    }

    /// Positions shown in the visual snap palette (3×3 + extras).
    static var palettePositions: [WindowPosition] {
        [
            .topLeft, .topHalf, .topRight,
            .leftHalf, .fullScreen, .rightHalf,
            .bottomLeft, .bottomHalf, .bottomRight,
            .thirdLeft, .thirdCenter, .thirdRight,
            .leftTwoFifths, .center, .rightThreeFifths,
            .topLeftSixth, .topCenterSixth, .topRightSixth,
            .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
        ]
    }

    func getFrame(for screen: NSScreen) -> CGRect {
        let screenFrame = screen.visibleFrame
        let width = screenFrame.width
        let height = screenFrame.height
        let minX = screenFrame.minX
        let minY = screenFrame.minY

        switch self {
        case .leftHalf:
            return CGRect(x: minX, y: minY, width: width / 2, height: height)
        case .rightHalf:
            return CGRect(x: minX + width / 2, y: minY, width: width / 2, height: height)
        case .topHalf:
            return CGRect(x: minX, y: minY + height / 2, width: width, height: height / 2)
        case .bottomHalf:
            return CGRect(x: minX, y: minY, width: width, height: height / 2)
        case .fullScreen:
            return screenFrame
        case .center:
            let centeredWidth = width * 0.8
            let centeredHeight = height * 0.8
            return CGRect(
                x: minX + (width - centeredWidth) / 2,
                y: minY + (height - centeredHeight) / 2,
                width: centeredWidth,
                height: centeredHeight
            )
        case .topLeft:
            return CGRect(x: minX, y: minY + height / 2, width: width / 2, height: height / 2)
        case .topRight:
            return CGRect(x: minX + width / 2, y: minY + height / 2, width: width / 2, height: height / 2)
        case .bottomLeft:
            return CGRect(x: minX, y: minY, width: width / 2, height: height / 2)
        case .bottomRight:
            return CGRect(x: minX + width / 2, y: minY, width: width / 2, height: height / 2)
        case .thirdLeft:
            return CGRect(x: minX, y: minY, width: width / 3, height: height)
        case .thirdCenter:
            return CGRect(x: minX + width / 3, y: minY, width: width / 3, height: height)
        case .thirdRight:
            return CGRect(x: minX + (width * 2 / 3), y: minY, width: width / 3, height: height)
        case .twoThirdsLeft:
            return CGRect(x: minX, y: minY, width: (width * 2 / 3), height: height)
        case .twoThirdsRight:
            return CGRect(x: minX + (width / 3), y: minY, width: (width * 2 / 3), height: height)
        case .topLeftSixth:
            return CGRect(x: minX, y: minY + height / 2, width: width / 3, height: height / 2)
        case .topCenterSixth:
            return CGRect(x: minX + width / 3, y: minY + height / 2, width: width / 3, height: height / 2)
        case .topRightSixth:
            return CGRect(x: minX + width * 2 / 3, y: minY + height / 2, width: width / 3, height: height / 2)
        case .bottomLeftSixth:
            return CGRect(x: minX, y: minY, width: width / 3, height: height / 2)
        case .bottomCenterSixth:
            return CGRect(x: minX + width / 3, y: minY, width: width / 3, height: height / 2)
        case .bottomRightSixth:
            return CGRect(x: minX + width * 2 / 3, y: minY, width: width / 3, height: height / 2)
        case .leftTwoFifths:
            return CGRect(x: minX, y: minY, width: width * 0.4, height: height)
        case .rightThreeFifths:
            return CGRect(x: minX + width * 0.4, y: minY, width: width * 0.6, height: height)
        case .leftThreeFifths:
            return CGRect(x: minX, y: minY, width: width * 0.6, height: height)
        case .rightTwoFifths:
            return CGRect(x: minX + width * 0.6, y: minY, width: width * 0.4, height: height)
        case .almostMaximize:
            let inset: CGFloat = 24
            return screenFrame.insetBy(dx: inset, dy: inset)
        }
    }
}
