import Foundation
import os.log

class Logger {
    static let shared = Logger()

    private let osLog = OSLog(subsystem: "com.panevo.app", category: "general")

    private init() {}

    enum LogLevel {
        case debug
        case info
        case warning
        case error

        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            }
        }
    }

    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"

        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)

        #if DEBUG
        print("[\(level)] \(logMessage)")
        #endif
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = error != nil ? "\(message) - \(error!.localizedDescription)" : message
        log(errorMessage, level: .error, file: file, function: function, line: line)
    }
}
