import Foundation
import AppKit

protocol PanevoError: Error {
    var localizedDescription: String { get }
    var errorCode: Int { get }
}

enum WindowManagerError: PanevoError {
    case windowNotFound
    case accessibilityDenied
    case invalidWindowFrame
    case animationFailed
    case displayNotFound

    var errorCode: Int {
        switch self {
        case .windowNotFound:
            return 1001
        case .accessibilityDenied:
            return 1002
        case .invalidWindowFrame:
            return 1003
        case .animationFailed:
            return 1004
        case .displayNotFound:
            return 1005
        }
    }

    var localizedDescription: String {
        switch self {
        case .windowNotFound:
            return "The requested window could not be found."
        case .accessibilityDenied:
            return "Accessibility permission is required to control windows."
        case .invalidWindowFrame:
            return "The window frame is invalid."
        case .animationFailed:
            return "The animation could not be completed."
        case .displayNotFound:
            return "The display could not be found."
        }
    }
}

enum SettingsError: PanevoError {
    case failedToSave
    case failedToLoad
    case invalidData
    case corruptedData

    var errorCode: Int {
        switch self {
        case .failedToSave:
            return 2001
        case .failedToLoad:
            return 2002
        case .invalidData:
            return 2003
        case .corruptedData:
            return 2004
        }
    }

    var localizedDescription: String {
        switch self {
        case .failedToSave:
            return "Failed to save settings."
        case .failedToLoad:
            return "Failed to load settings."
        case .invalidData:
            return "Settings data is invalid."
        case .corruptedData:
            return "Settings data is corrupted."
        }
    }
}

enum KeyboardError: PanevoError {
    case hotkeyRegistrationFailed
    case conflictingShortcuts
    case invalidKeyCode

    var errorCode: Int {
        switch self {
        case .hotkeyRegistrationFailed:
            return 3001
        case .conflictingShortcuts:
            return 3002
        case .invalidKeyCode:
            return 3003
        }
    }

    var localizedDescription: String {
        switch self {
        case .hotkeyRegistrationFailed:
            return "Failed to register the keyboard shortcut."
        case .conflictingShortcuts:
            return "This keyboard shortcut conflicts with another."
        case .invalidKeyCode:
            return "The key code is invalid."
        }
    }
}

class ErrorRecovery {
    static func recoverFromWindowError(_ error: WindowManagerError) -> String {
        switch error {
        case .accessibilityDenied:
            return "Please grant Panevo accessibility permission in System Settings → Privacy & Security → Accessibility."
        case .windowNotFound:
            return "The window could not be found. Try clicking on the window first."
        case .invalidWindowFrame:
            return "The window frame is invalid. Try snapping again."
        case .animationFailed:
            return "The animation failed. Trying to snap without animation."
        case .displayNotFound:
            return "The display could not be found. Check that all displays are connected."
        }
    }

    static func logError(_ error: Error, context: String = "") {
        let errorMessage = "\(context): \(error.localizedDescription)"
        Logger.shared.error(errorMessage)
    }

    static func handleFatalError(_ error: Error) {
        logError(error, context: "Fatal Error")

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    static func handleWarning(_ error: Error) {
        logError(error, context: "Warning")

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Warning"
            alert.informativeText = error.localizedDescription
            alert.addButton(withTitle: "OK")
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}

class ResultHandler<T, E: PanevoError> {
    typealias Completion = (Result<T, E>) -> Void

    static func execute(_ work: @escaping () throws -> T, onCompletion: @escaping Completion) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try work()
                DispatchQueue.main.async {
                    onCompletion(.success(result))
                }
            } catch let error as E {
                DispatchQueue.main.async {
                    onCompletion(.failure(error))
                }
            } catch {
                Logger.shared.error("Unexpected error: \(error)")
            }
        }
    }
}
