import AppKit
import SwiftUI

class PreferencesWindowController: NSWindowController {
    let viewModel: PanevoViewModel

    convenience init(viewModel: PanevoViewModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let rootView = PreferencesView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: rootView)

        window.contentView = hostingView
        window.title = "Panevo Preferences"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        self.windowFrameAutosaveName = "PreferencesWindow"
    }

    override init(window: NSWindow?) {
        let displayManager = DisplayManager()
        let accessibilityManager = AccessibilityManager.shared
        let windowManager = WindowManager(displayManager: displayManager, accessibilityManager: accessibilityManager)
        let hotKeyManager = HotKeyManager(windowManager: windowManager)

        self.viewModel = PanevoViewModel(
            windowManager: windowManager,
            hotKeyManager: hotKeyManager,
            displayManager: displayManager,
            accessibilityManager: accessibilityManager,
            settingsManager: SettingsManager.shared
        )

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.delegate = self
    }
}

extension PreferencesWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        viewModel.updateSettings()
    }
}

struct PreferencesView: View {
    let viewModel: PanevoViewModel

    var body: some View {
        VStack {
            Text("Preferences")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    let displayManager = DisplayManager()
    let accessibilityManager = AccessibilityManager.shared
    let windowManager = WindowManager(displayManager: displayManager, accessibilityManager: accessibilityManager)
    let hotKeyManager = HotKeyManager(windowManager: windowManager)

    return PreferencesView(viewModel: PanevoViewModel(
        windowManager: windowManager,
        hotKeyManager: hotKeyManager,
        displayManager: displayManager,
        accessibilityManager: accessibilityManager,
        settingsManager: SettingsManager.shared
    ))
}
