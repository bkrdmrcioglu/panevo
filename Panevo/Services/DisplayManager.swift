import Foundation
import AppKit
import Combine

class DisplayManager: ObservableObject {
    @Published var displays: [DisplayInfo] = []
    @Published var mainDisplay: DisplayInfo?

    private var displayChangeObserver: NSObjectProtocol?

    init() {
        updateDisplays()
        registerForDisplayChanges()
    }

    deinit {
        if let observer = displayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func updateDisplays() {
        var displayCount: UInt32 = 0
        var result = CGGetActiveDisplayList(0, nil, &displayCount)

        guard result == .success else { return }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        result = CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)

        guard result == .success else { return }

        displays = displayIDs.map { DisplayInfo(displayID: $0) }.sorted { a, b in
            a.isMain && !b.isMain
        }

        mainDisplay = displays.first(where: { $0.isMain })
    }

    private func registerForDisplayChanges() {
        displayChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDisplays()
        }
    }

    func getDisplayContainingPoint(_ point: CGPoint) -> DisplayInfo? {
        return displays.first { NSScreen.screen(for: $0.id)?.frame.contains(point) ?? false }
    }

    func getDisplayContainingFrame(_ frame: CGRect) -> DisplayInfo? {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return getDisplayContainingPoint(center)
    }

    func getNextDisplay(from current: DisplayInfo) -> DisplayInfo? {
        guard let currentIndex = displays.firstIndex(where: { $0.id == current.id }) else { return nil }
        let nextIndex = (currentIndex + 1) % displays.count
        return displays[nextIndex]
    }

    func getPreviousDisplay(from current: DisplayInfo) -> DisplayInfo? {
        guard let currentIndex = displays.firstIndex(where: { $0.id == current.id }) else { return nil }
        let previousIndex = (currentIndex - 1 + displays.count) % displays.count
        return displays[previousIndex]
    }
}
