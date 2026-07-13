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
            (NSLocalizedString("Center", comment: ""), "rectangle.center.inset.filled", .center),
        ]

        for (title, icon, position) in snapActions {
            let item = NSMenuItem(title: title, action: #selector(snapAction(_:)), keyEquivalent: "")
            item.target = self
            item.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
            item.representedObject = position.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let nextDisplayItem = NSMenuItem(title: NSLocalizedString("Move to Next Display", comment: ""), action: #selector(moveToNextDisplay), keyEquivalent: "")
        nextDisplayItem.target = self
        nextDisplayItem.image = NSImage(systemSymbolName: "arrow.right.square", accessibilityDescription: "Next Display")
        menu.addItem(nextDisplayItem)

        menu.addItem(.separator())

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

    @objc private func moveToNextDisplay() {
        windowManager?.moveWindowToNextDisplay()
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
