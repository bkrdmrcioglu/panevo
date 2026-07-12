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

    var displayName: String {
        switch self {
        case .leftHalf:
            return "Left Half"
        case .rightHalf:
            return "Right Half"
        case .topHalf:
            return "Top Half"
        case .bottomHalf:
            return "Bottom Half"
        case .fullScreen:
            return "Full Screen"
        case .center:
            return "Center"
        case .topLeft:
            return "Top Left"
        case .topRight:
            return "Top Right"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        case .thirdLeft:
            return "Left Third"
        case .thirdCenter:
            return "Center Third"
        case .thirdRight:
            return "Right Third"
        case .twoThirdsLeft:
            return "Two Thirds Left"
        case .twoThirdsRight:
            return "Two Thirds Right"
        }
    }

    var symbolName: String {
        switch self {
        case .leftHalf:
            return "rectangle.split.2.vertical"
        case .rightHalf:
            return "rectangle.split.2.vertical"
        case .topHalf:
            return "rectangle.split.2.horizontal"
        case .bottomHalf:
            return "rectangle.split.2.horizontal"
        case .fullScreen:
            return "rectangle"
        case .center:
            return "square"
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return "square.grid.2x2"
        case .thirdLeft, .thirdCenter, .thirdRight:
            return "rectangle.split.3.vertical"
        case .twoThirdsLeft, .twoThirdsRight:
            return "rectangle.split.3.vertical"
        }
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
            return CGRect(x: minX + (width - centeredWidth) / 2, y: minY + (height - centeredHeight) / 2, width: centeredWidth, height: centeredHeight)
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
        }
    }
}
