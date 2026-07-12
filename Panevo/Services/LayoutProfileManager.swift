import Foundation
import AppKit

class LayoutProfileManager {
    private let accessibilityManager: AccessibilityManager
    private let displayManager: DisplayManager

    init(accessibilityManager: AccessibilityManager, displayManager: DisplayManager) {
        self.accessibilityManager = accessibilityManager
        self.displayManager = displayManager
    }

    // MARK: - Capture

    func captureCurrentLayout(name: String) -> LayoutProfile {
        var snapshots: [WindowLayoutSnapshot] = []
        let ownPid = ProcessInfo.processInfo.processIdentifier

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  app.processIdentifier != ownPid,
                  let bundleID = app.bundleIdentifier,
                  let element = accessibilityManager.getAccessibilityElement(for: app.processIdentifier) else {
                continue
            }

            for window in accessibilityManager.getAllWindows(from: element) {
                guard let position = accessibilityManager.getWindowPosition(from: window),
                      let size = accessibilityManager.getWindowSize(from: window),
                      size.width > 1, size.height > 1 else {
                    continue
                }

                let frame = CGRect(origin: position, size: size)
                let title = accessibilityManager.getWindowTitle(from: window) ?? ""
                let displayID = displayManager.getDisplayContainingFrame(frame)?.id ?? CGMainDisplayID()

                snapshots.append(WindowLayoutSnapshot(
                    appBundleIdentifier: bundleID,
                    windowTitle: title,
                    position: .center,
                    displayID: displayID,
                    frame: frame
                ))
            }
        }

        return LayoutProfile(name: name, displayName: name, windowLayouts: snapshots)
    }

    // MARK: - Apply

    @discardableResult
    func apply(_ profile: LayoutProfile) -> Int {
        launchMissingApps(for: profile)
        return applyToRunningApps(profile)
    }

    // Launches apps in the profile that aren't running, then places their
    // windows once they've had a moment to appear.
    private func launchMissingApps(for profile: LayoutProfile) {
        let runningBundles = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        let neededBundles = Set(profile.windowLayouts.map { $0.appBundleIdentifier })
        let missing = neededBundles.subtracting(runningBundles)

        guard !missing.isEmpty else { return }

        for bundleID in missing {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { continue }
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.applyToRunningApps(profile)
        }
    }

    @discardableResult
    private func applyToRunningApps(_ profile: LayoutProfile) -> Int {
        var restoredCount = 0
        let snapshotsByBundle = Dictionary(grouping: profile.windowLayouts, by: { $0.appBundleIdentifier })

        for app in NSWorkspace.shared.runningApplications {
            guard let bundleID = app.bundleIdentifier,
                  var snapshots = snapshotsByBundle[bundleID],
                  let element = accessibilityManager.getAccessibilityElement(for: app.processIdentifier) else {
                continue
            }

            for window in accessibilityManager.getAllWindows(from: element) {
                guard !snapshots.isEmpty else { break }

                let title = accessibilityManager.getWindowTitle(from: window) ?? ""

                // Prefer an exact title match, otherwise consume the next snapshot.
                let index = snapshots.firstIndex(where: { $0.windowTitle == title && !title.isEmpty }) ?? 0
                let snapshot = snapshots.remove(at: index)

                guard let frame = snapshot.frame else { continue }

                if accessibilityManager.setWindowFrame(frame, for: window) {
                    restoredCount += 1
                }
            }
        }

        return restoredCount
    }
}
