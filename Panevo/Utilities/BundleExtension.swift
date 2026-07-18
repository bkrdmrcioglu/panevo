import Foundation
import AppKit

extension Bundle {
    var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }

    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Non-optional bundle id — do not name this `bundleIdentifier` or it shadows
    /// Foundation's property and recurses until the stack overflows.
    var identifierString: String {
        infoDictionary?["CFBundleIdentifier"] as? String ?? "unknown"
    }

    var displayName: String {
        return self.infoDictionary?["CFBundleDisplayName"] as? String ?? appName
    }

    var appIcon: NSImage? {
        if let iconName = infoDictionary?["CFBundleIconFile"] as? String {
            return NSImage(named: iconName)
        }
        return nil
    }

    static var appVersion: String {
        return Bundle.main.appVersion
    }

    static var buildNumber: String {
        return Bundle.main.buildNumber
    }

    static var appName: String {
        return Bundle.main.appName
    }

    static var versionString: String {
        let version = Bundle.main.appVersion
        let build = Bundle.main.buildNumber
        return "v\(version) (\(build))"
    }
}

extension NSApplication {
    var appBundle: Bundle {
        return Bundle.main
    }

    var appName: String {
        return Bundle.main.appName
    }

    var appVersion: String {
        return Bundle.main.appVersion
    }
}

class ApplicationHelper {
    static func getApplicationIcon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: url.path)
    }

    static func getApplicationName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }

        let bundle = Bundle(url: url)
        return bundle?.appName
    }

    static func getAllApplications() -> [RunningApplication] {
        var applications: [RunningApplication] = []

        for app in NSWorkspace.shared.runningApplications {
            let appInfo = RunningApplication(
                bundleIdentifier: app.bundleIdentifier ?? "unknown",
                processIdentifier: app.processIdentifier,
                applicationName: app.localizedName ?? "Unknown",
                icon: NSWorkspace.shared.icon(forFile: app.bundleURL?.path ?? "")
            )
            applications.append(appInfo)
        }

        return applications.sorted { $0.applicationName.localizedCaseInsensitiveCompare($1.applicationName) == .orderedAscending }
    }
}

struct RunningApplication: Identifiable, Equatable {
    let id = UUID()
    let bundleIdentifier: String
    let processIdentifier: pid_t
    let applicationName: String
    let icon: NSImage?

    static func == (lhs: RunningApplication, rhs: RunningApplication) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.processIdentifier == rhs.processIdentifier
    }
}
