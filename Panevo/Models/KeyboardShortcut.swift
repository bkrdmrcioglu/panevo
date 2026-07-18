import Foundation
import Carbon

struct KeyboardShortcut: Identifiable, Codable, Equatable {
    let id: UUID
    var action: SnapAction
    var keyCode: UInt32
    var modifiers: UInt32
    var isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, action, keyCode, modifiers, isEnabled
    }

    init(action: SnapAction, keyCode: UInt32, modifiers: UInt32, isEnabled: Bool = true) {
        self.id = UUID()
        self.action = action
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }

    var displayName: String {
        var result = ""

        if modifiers & UInt32(cmdKey) != 0 {
            result += "⌘"
        }
        if modifiers & UInt32(optionKey) != 0 {
            result += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            result += "⇧"
        }
        if modifiers & UInt32(controlKey) != 0 {
            result += "⌃"
        }

        if let keyName = keyCodeToString(keyCode) {
            result += keyName
        }

        return result
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_ANSI_1): return "1"
        case UInt32(kVK_ANSI_2): return "2"
        case UInt32(kVK_ANSI_3): return "3"
        case UInt32(kVK_ANSI_4): return "4"
        case UInt32(kVK_ANSI_5): return "5"
        case UInt32(kVK_ANSI_6): return "6"
        case UInt32(kVK_ANSI_7): return "7"
        case UInt32(kVK_ANSI_8): return "8"
        case UInt32(kVK_ANSI_9): return "9"
        case UInt32(kVK_ANSI_0): return "0"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_F1): return "F1"
        case UInt32(kVK_F2): return "F2"
        case UInt32(kVK_F3): return "F3"
        case UInt32(kVK_F4): return "F4"
        case UInt32(kVK_F5): return "F5"
        case UInt32(kVK_F6): return "F6"
        case UInt32(kVK_F7): return "F7"
        case UInt32(kVK_F8): return "F8"
        case UInt32(kVK_F9): return "F9"
        case UInt32(kVK_F10): return "F10"
        case UInt32(kVK_F11): return "F11"
        case UInt32(kVK_F12): return "F12"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        default: return nil
        }
    }

    static var defaultShortcuts: [KeyboardShortcut] {
        let ctrlOpt = UInt32(controlKey | optionKey)
        return [
            KeyboardShortcut(action: .leftHalf, keyCode: UInt32(kVK_LeftArrow), modifiers: ctrlOpt),
            KeyboardShortcut(action: .rightHalf, keyCode: UInt32(kVK_RightArrow), modifiers: ctrlOpt),
            KeyboardShortcut(action: .topHalf, keyCode: UInt32(kVK_UpArrow), modifiers: ctrlOpt),
            KeyboardShortcut(action: .bottomHalf, keyCode: UInt32(kVK_DownArrow), modifiers: ctrlOpt),
            KeyboardShortcut(action: .fullScreen, keyCode: UInt32(kVK_Return), modifiers: ctrlOpt),
            KeyboardShortcut(action: .center, keyCode: UInt32(kVK_ANSI_C), modifiers: ctrlOpt),
            KeyboardShortcut(action: .restore, keyCode: UInt32(kVK_Delete), modifiers: ctrlOpt),
            KeyboardShortcut(action: .undo, keyCode: UInt32(kVK_ANSI_Z), modifiers: ctrlOpt),
            KeyboardShortcut(action: .moveToNextDisplay, keyCode: UInt32(kVK_ANSI_N), modifiers: ctrlOpt),
            KeyboardShortcut(action: .moveToPreviousDisplay, keyCode: UInt32(kVK_ANSI_P), modifiers: ctrlOpt),
            KeyboardShortcut(action: .tileAll, keyCode: UInt32(kVK_ANSI_T), modifiers: ctrlOpt, isEnabled: false),
            KeyboardShortcut(action: .showPalette, keyCode: UInt32(kVK_Space), modifiers: ctrlOpt, isEnabled: false),
            KeyboardShortcut(action: .almostMaximize, keyCode: UInt32(kVK_ANSI_M), modifiers: ctrlOpt, isEnabled: false),
        ]
    }

    static func == (lhs: KeyboardShortcut, rhs: KeyboardShortcut) -> Bool {
        return lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
    }
}

enum SnapAction: String, Codable, CaseIterable, Identifiable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case fullScreen
    case center
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case thirdLeft
    case thirdCenter
    case thirdRight
    case twoThirdsLeft
    case twoThirdsRight
    case topLeftSixth
    case topCenterSixth
    case topRightSixth
    case bottomLeftSixth
    case bottomCenterSixth
    case bottomRightSixth
    case leftTwoFifths
    case rightThreeFifths
    case leftThreeFifths
    case rightTwoFifths
    case almostMaximize
    case moveToNextDisplay
    case moveToPreviousDisplay
    case restore
    case undo
    case tileAll
    case showPalette

    var id: String { self.rawValue }

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
        case .moveToNextDisplay: return "Move to Next Display"
        case .moveToPreviousDisplay: return "Move to Previous Display"
        case .restore: return "Restore"
        case .undo: return "Undo Last Snap"
        case .tileAll: return "Tile All Windows"
        case .showPalette: return "Show Snap Palette"
        }
    }

    func getWindowPosition() -> WindowPosition? {
        switch self {
        case .leftHalf: return .leftHalf
        case .rightHalf: return .rightHalf
        case .topHalf: return .topHalf
        case .bottomHalf: return .bottomHalf
        case .fullScreen: return .fullScreen
        case .center: return .center
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        case .thirdLeft: return .thirdLeft
        case .thirdCenter: return .thirdCenter
        case .thirdRight: return .thirdRight
        case .twoThirdsLeft: return .twoThirdsLeft
        case .twoThirdsRight: return .twoThirdsRight
        case .topLeftSixth: return .topLeftSixth
        case .topCenterSixth: return .topCenterSixth
        case .topRightSixth: return .topRightSixth
        case .bottomLeftSixth: return .bottomLeftSixth
        case .bottomCenterSixth: return .bottomCenterSixth
        case .bottomRightSixth: return .bottomRightSixth
        case .leftTwoFifths: return .leftTwoFifths
        case .rightThreeFifths: return .rightThreeFifths
        case .leftThreeFifths: return .leftThreeFifths
        case .rightTwoFifths: return .rightTwoFifths
        case .almostMaximize: return .almostMaximize
        case .moveToNextDisplay, .moveToPreviousDisplay, .restore, .undo, .tileAll, .showPalette:
            return nil
        }
    }
}
