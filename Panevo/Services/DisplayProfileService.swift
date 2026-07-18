import Foundation
import AppKit

/// Applies a saved layout when the active display count changes (dock / undock).
final class DisplayProfileService {
    private let displayManager: DisplayManager
    private let layoutProfileManager: LayoutProfileManager
    private var observer: NSObjectProtocol?
    private var lastDisplayCount: Int = 0
    private var applyWorkItem: DispatchWorkItem?

    init(displayManager: DisplayManager, layoutProfileManager: LayoutProfileManager) {
        self.displayManager = displayManager
        self.layoutProfileManager = layoutProfileManager
        lastDisplayCount = NSScreen.screens.count
        register()
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func register() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisplayChange()
        }
    }

    private func handleDisplayChange() {
        guard SettingsManager.shared.autoApplyDisplayProfiles else { return }

        let count = NSScreen.screens.count
        defer { lastDisplayCount = count }
        guard count != lastDisplayCount else { return }

        applyWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applyBinding(for: count)
        }
        applyWorkItem = work
        // Wait for displays to settle after dock/undock.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    private func applyBinding(for count: Int) {
        guard let binding = SettingsManager.shared.binding(forDisplayCount: count),
              let profile = SettingsManager.shared.layoutProfiles.first(where: { $0.id == binding.layoutProfileID }) else {
            return
        }
        _ = layoutProfileManager.apply(profile)
    }
}
