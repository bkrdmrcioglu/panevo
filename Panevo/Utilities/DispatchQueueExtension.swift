import Foundation

extension DispatchQueue {
    static let windowManager = DispatchQueue(label: "com.panevo.windowManager", qos: .userInteractive)
    static let hotkeyManager = DispatchQueue(label: "com.panevo.hotkeyManager", qos: .userInteractive)
    static let displayManager = DispatchQueue(label: "com.panevo.displayManager", qos: .userInitiated)
    static let settings = DispatchQueue(label: "com.panevo.settings", qos: .userInitiated)

    func asyncAfter(seconds: TimeInterval, execute work: @escaping @convention(block) () -> Void) {
        asyncAfter(deadline: .now() + seconds, execute: work)
    }

    func performOnMainThread(execute work: @escaping @convention(block) () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    func performOnMainThreadSync(execute work: @escaping @convention(block) () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }
}
