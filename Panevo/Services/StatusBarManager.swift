import Foundation
import AppKit
import SwiftUI

class StatusBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private let hotKeyManager: HotKeyManager
    private let settingsManager: SettingsManager
    private let windowManager: WindowManager?
    private var mainWindow: NSWindow?

    init(hotKeyManager: HotKeyManager, settingsManager: SettingsManager, windowManager: WindowManager? = nil) {
        self.hotKeyManager = hotKeyManager
        self.settingsManager = settingsManager
        self.windowManager = windowManager
        super.init()
        setupStatusBar()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Panevo")
        }

        let menu = NSMenu()

        let openItem = NSMenuItem(title: NSLocalizedString("Open Panevo", comment: ""), action: #selector(openMainWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let snapActions: [(String, String, WindowPosition)] = [
            (NSLocalizedString("Left Half", comment: ""), "rectangle.lefthalf.filled", .leftHalf),
            (NSLocalizedString("Right Half", comment: ""), "rectangle.righthalf.filled", .rightHalf),
            (NSLocalizedString("Top Half", comment: ""), "rectangle.tophalf.filled", .topHalf),
            (NSLocalizedString("Bottom Half", comment: ""), "rectangle.bottomhalf.filled", .bottomHalf),
            (NSLocalizedString("Maximize", comment: ""), "rectangle.fill", .fullScreen),
            (NSLocalizedString("Almost Maximize", comment: ""), "rectangle.inset.filled", .almostMaximize),
            (NSLocalizedString("Center", comment: ""), "rectangle.center.inset.filled", .center),
            (NSLocalizedString("Left 40%", comment: ""), "rectangle.lefthalf.inset.filled", .leftTwoFifths),
            (NSLocalizedString("Right 60%", comment: ""), "rectangle.righthalf.inset.filled", .rightThreeFifths),
        ]

        for (title, icon, position) in snapActions {
            let item = NSMenuItem(title: title, action: #selector(snapAction(_:)), keyEquivalent: "")
            item.target = self
            item.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
            item.representedObject = position.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let paletteItem = NSMenuItem(title: NSLocalizedString("Show Snap Palette", comment: ""), action: #selector(showPalette), keyEquivalent: "")
        paletteItem.target = self
        paletteItem.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "Palette")
        menu.addItem(paletteItem)

        let tileItem = NSMenuItem(title: NSLocalizedString("Tile All Windows", comment: ""), action: #selector(tileAll), keyEquivalent: "")
        tileItem.target = self
        tileItem.image = NSImage(systemSymbolName: "rectangle.split.3x3", accessibilityDescription: "Tile")
        menu.addItem(tileItem)

        let undoItem = NSMenuItem(title: NSLocalizedString("Undo Last Snap", comment: ""), action: #selector(undoSnap), keyEquivalent: "")
        undoItem.target = self
        undoItem.image = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "Undo")
        menu.addItem(undoItem)

        menu.addItem(.separator())

        let nextDisplayItem = NSMenuItem(title: NSLocalizedString("Move to Next Display", comment: ""), action: #selector(moveToNextDisplay), keyEquivalent: "")
        nextDisplayItem.target = self
        nextDisplayItem.image = NSImage(systemSymbolName: "arrow.right.square", accessibilityDescription: "Next Display")
        menu.addItem(nextDisplayItem)

        menu.addItem(.separator())

        let updateItem = NSMenuItem(title: NSLocalizedString("Check for Updates", comment: ""), action: #selector(checkUpdates), keyEquivalent: "")
        updateItem.target = self
        updateItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Updates")
        menu.addItem(updateItem)

        let supportItem = NSMenuItem(title: NSLocalizedString("Buy Me a Coffee", comment: ""), action: #selector(openSupportPage), keyEquivalent: "")
        supportItem.target = self
        supportItem.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Support")
        menu.addItem(supportItem)

        let quitItem = NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func snapAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let position = WindowPosition(rawValue: raw) else { return }
        windowManager?.snapWindow(to: position)
    }

    @objc private func showPalette() {
        windowManager?.showSnapPalette()
    }

    @objc private func tileAll() {
        windowManager?.tileAllWindows()
    }

    @objc private func undoSnap() {
        windowManager?.undoLastSnap()
    }

    @objc private func moveToNextDisplay() {
        windowManager?.moveWindowToNextDisplay()
    }

    @objc private func checkUpdates() {
        UpdateChecker.shared.checkForUpdates(openIfAvailable: true)
    }

    @objc private func openMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Panevo"
        window.contentView = NSHostingView(rootView: ContentView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        mainWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSupportPage() {
        if let url = URL(string: "https://buymeacoffee.com/bkrdmrcioglu") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
