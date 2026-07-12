import Foundation
import AppKit
import Carbon
import Combine

extension Notification.Name {
    static let panevoShortcutsChanged = Notification.Name("panevoShortcutsChanged")
}

class HotKeyManager: ObservableObject {
    @Published var isActive = false

    private let windowManager: WindowManager
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var actionsByID: [UInt32: SnapAction] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextHotKeyID: UInt32 = 1
    private var shortcutsObserver: NSObjectProtocol?

    private static let signature: OSType = 0x504E5645 // "PNVE"

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        installEventHandler()
        registerShortcuts(SettingsManager.shared.shortcuts)

        shortcutsObserver = NotificationCenter.default.addObserver(
            forName: .panevoShortcutsChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadShortcuts()
        }
    }

    deinit {
        for ref in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let observer = shortcutsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Registration

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event = event, let userData = userData else { return noErr }

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                // Pass unrecognized hotkeys along so another handler in this
                // process (a second HotKeyManager instance) can process them.
                return manager.handleHotKey(id: hotKeyID.id) ? noErr : OSStatus(eventNotHandledErr)
            },
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )

        isActive = status == noErr
    }

    func registerShortcuts(_ shortcuts: [KeyboardShortcut]) {
        for shortcut in shortcuts where shortcut.isEnabled {
            registerShortcut(shortcut)
        }
    }

    func registerShortcut(_ shortcut: KeyboardShortcut) {
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: nextHotKeyID)
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
            actionsByID[nextHotKeyID] = shortcut.action
            nextHotKeyID += 1
        }
    }

    func unregisterAll() {
        for ref in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
        actionsByID.removeAll()
    }

    func unregisterShortcut(_ shortcut: KeyboardShortcut) {
        reloadShortcuts()
    }

    func updateShortcut(_ shortcut: KeyboardShortcut) {
        reloadShortcuts()
    }

    // Re-registers everything from the persisted settings; simpler and safer
    // than tracking individual EventHotKeyRefs per shortcut.
    func reloadShortcuts() {
        unregisterAll()
        registerShortcuts(SettingsManager.shared.shortcuts)
    }

    func detectConflicts() -> [(KeyboardShortcut, KeyboardShortcut)] {
        let shortcuts = SettingsManager.shared.shortcuts.filter { $0.isEnabled }
        var conflicts: [(KeyboardShortcut, KeyboardShortcut)] = []

        for i in shortcuts.indices {
            for j in shortcuts.indices where j > i {
                if shortcuts[i].keyCode == shortcuts[j].keyCode &&
                    shortcuts[i].modifiers == shortcuts[j].modifiers {
                    conflicts.append((shortcuts[i], shortcuts[j]))
                }
            }
        }
        return conflicts
    }

    // MARK: - Handling

    @discardableResult
    private func handleHotKey(id: UInt32) -> Bool {
        guard let action = actionsByID[id] else { return false }

        DispatchQueue.main.async { [weak self] in
            self?.perform(action)
        }
        return true
    }

    private func perform(_ action: SnapAction) {
        switch action {
        case .leftHalf: windowManager.snapWindow(to: .leftHalf)
        case .rightHalf: windowManager.snapWindow(to: .rightHalf)
        case .topHalf: windowManager.snapWindow(to: .topHalf)
        case .bottomHalf: windowManager.snapWindow(to: .bottomHalf)
        case .fullScreen: windowManager.snapWindow(to: .fullScreen)
        case .center: windowManager.snapWindow(to: .center)
        case .topLeft: windowManager.snapWindow(to: .topLeft)
        case .topRight: windowManager.snapWindow(to: .topRight)
        case .bottomLeft: windowManager.snapWindow(to: .bottomLeft)
        case .bottomRight: windowManager.snapWindow(to: .bottomRight)
        case .thirdLeft: windowManager.snapWindow(to: .thirdLeft)
        case .thirdCenter: windowManager.snapWindow(to: .thirdCenter)
        case .thirdRight: windowManager.snapWindow(to: .thirdRight)
        case .twoThirdsLeft: windowManager.snapWindow(to: .twoThirdsLeft)
        case .twoThirdsRight: windowManager.snapWindow(to: .twoThirdsRight)
        case .moveToNextDisplay: windowManager.moveWindowToNextDisplay()
        case .moveToPreviousDisplay: windowManager.moveWindowToPreviousDisplay()
        }
    }
}
