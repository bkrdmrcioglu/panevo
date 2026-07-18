import SwiftUI
import Carbon
import AppKit

// MARK: - Root

struct ContentView: View {
    @StateObject private var viewModel: PanevoViewModel
    @State private var selectedTab: SidebarTab = .dashboard

    enum SidebarTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case shortcuts = "Shortcuts"
        case layouts = "Layouts"
        case rules = "Rules"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .shortcuts: return "keyboard.fill"
            case .layouts: return "rectangle.3.group.fill"
            case .rules: return "app.badge.checkmark.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    init() {
        let displayManager = DisplayManager()
        let accessibilityManager = AccessibilityManager.shared
        let windowManager = WindowManager(displayManager: displayManager, accessibilityManager: accessibilityManager)
        let hotKeyManager = HotKeyManager(windowManager: windowManager)
        let settingsManager = SettingsManager.shared

        _viewModel = StateObject(wrappedValue: PanevoViewModel(
            windowManager: windowManager,
            hotKeyManager: hotKeyManager,
            displayManager: displayManager,
            accessibilityManager: accessibilityManager,
            settingsManager: settingsManager
        ))
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $selectedTab)

            Divider()

            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: viewModel)
                case .shortcuts:
                    ShortcutsView(viewModel: viewModel)
                case .layouts:
                    LayoutsView(viewModel: viewModel)
                case .rules:
                    RulesPaneView()
                case .settings:
                    SettingsPaneView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 820, minHeight: 620)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: ContentView.SidebarTab

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBlue, Color.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "rectangle.split.2x1.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Panevo")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Window Manager")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 26)

            ForEach(ContentView.SidebarTab.allCases) { tab in
                SidebarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .frame(width: 200)
        .background(.ultraThinMaterial)
    }
}

struct SidebarButton: View {
    let tab: ContentView.SidebarTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .white : .secondary)
                Text(LocalizedStringKey(tab.rawValue))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color.accentBlue, Color.accentPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(isHovering ? Color.primary.opacity(0.07) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    let viewModel: PanevoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    title: "Dashboard",
                    subtitle: "Manage your windows with a single keystroke"
                )

                PermissionCard(viewModel: viewModel)

                SectionLabel(text: "Displays", icon: "display")
                DisplaysRow(displays: viewModel.displays)

                SectionLabel(text: "Quick Actions", icon: "bolt.fill")
                SnapGrid(viewModel: viewModel)
            }
            .padding(28)
        }
    }
}

struct PageHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct SectionLabel: View {
    let text: LocalizedStringKey
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.accentBlue)
            Text(text)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

struct PermissionCard: View {
    let viewModel: PanevoViewModel

    private var isEnabled: Bool { viewModel.isAccessibilityEnabled }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((isEnabled ? Color.green : Color.orange).opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: isEnabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isEnabled ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Accessibility Permission")
                    .font(.system(size: 14, weight: .semibold))
                Text(isEnabled
                     ? "Panevo can manage your windows."
                     : "Required to move and resize windows of other apps.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isEnabled {
                Button(action: { viewModel.requestAccessibilityPermission() }) {
                    Text("Grant Access")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color.accentBlue, Color.accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Card())
    }
}

struct DisplaysRow: View {
    let displays: [DisplayInfo]

    var body: some View {
        HStack(spacing: 14) {
            if displays.isEmpty {
                Text("No displays detected")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(16)
                    .background(Card())
            } else {
                ForEach(displays) { display in
                    HStack(spacing: 12) {
                        Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(Color.accentBlue)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(LocalizedStringKey(display.name))
                                    .font(.system(size: 13, weight: .semibold))
                                if display.isMain {
                                    Text("MAIN")
                                        .font(.system(size: 8, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(Capsule().fill(Color.accentBlue))
                                }
                            }
                            Text("\(Int(display.width)) × \(Int(display.height))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Card())
                }
                Spacer()
            }
        }
    }
}

// MARK: - Snap Grid

struct SnapGrid: View {
    let viewModel: PanevoViewModel

    private let actions: [(String, String, WindowPosition)] = [
        ("Left", "rectangle.lefthalf.filled", .leftHalf),
        ("Right", "rectangle.righthalf.filled", .rightHalf),
        ("Top", "rectangle.tophalf.filled", .topHalf),
        ("Bottom", "rectangle.bottomhalf.filled", .bottomHalf),
        ("Top Left", "rectangle.inset.topleft.filled", .topLeft),
        ("Top Right", "rectangle.inset.topright.filled", .topRight),
        ("Bottom Left", "rectangle.inset.bottomleft.filled", .bottomLeft),
        ("Bottom Right", "rectangle.inset.bottomright.filled", .bottomRight),
        ("Maximize", "rectangle.fill", .fullScreen),
        ("Center", "rectangle.center.inset.filled", .center),
        ("Left ⅓", "rectangle.leadingthird.inset.filled", .thirdLeft),
        ("Right ⅓", "rectangle.trailingthird.inset.filled", .thirdRight),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 12)], spacing: 12) {
            ForEach(actions, id: \.2) { label, icon, position in
                SnapButton(label: label, icon: icon) {
                    viewModel.snapWindow(to: position)
                }
            }
        }
    }
}

struct SnapButton: View {
    let label: String
    let icon: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(isHovering ? .white : Color.accentBlue)
                Text(LocalizedStringKey(label))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isHovering ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isHovering
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color.accentBlue, Color.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(Color.primary.opacity(0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(isHovering ? 0 : 0.07), lineWidth: 1)
            )
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Shortcuts

struct ShortcutsView: View {
    @ObservedObject var viewModel: PanevoViewModel
    @State private var recordingID: UUID?
    @State private var keyMonitor: Any?

    private var conflicts: [(KeyboardShortcut, KeyboardShortcut)] {
        viewModel.detectShortcutConflicts()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    title: "Shortcuts",
                    subtitle: "System-wide keyboard shortcuts, available in every app"
                )

                if !conflicts.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Conflicting shortcuts detected")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(12)
                    .background(Card())
                }

                VStack(spacing: 8) {
                    ForEach(viewModel.shortcuts, id: \.id) { shortcut in
                        ShortcutRow(
                            shortcut: shortcut,
                            isRecording: recordingID == shortcut.id,
                            onChange: { toggleRecording(for: shortcut) }
                        )
                    }
                }

                Button(action: {
                    stopRecording()
                    viewModel.resetShortcuts()
                }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
            }
            .padding(28)
        }
        .onDisappear { stopRecording() }
    }

    private func toggleRecording(for shortcut: KeyboardShortcut) {
        if recordingID == shortcut.id {
            stopRecording()
            return
        }

        stopRecording()
        recordingID = shortcut.id

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyEvent(event, for: shortcut)
            return nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent, for shortcut: KeyboardShortcut) {
        // Escape cancels recording.
        if event.keyCode == 53 {
            stopRecording()
            return
        }

        var carbonModifiers: UInt32 = 0
        if event.modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }

        // Require at least one non-shift modifier so plain typing can't be captured.
        guard carbonModifiers & ~UInt32(shiftKey) != 0 else { return }

        var updated = shortcut
        updated.keyCode = UInt32(event.keyCode)
        updated.modifiers = carbonModifiers
        updated.isEnabled = true

        stopRecording()
        viewModel.updateShortcut(updated)
    }

    private func stopRecording() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        recordingID = nil
    }
}

struct ShortcutRow: View {
    let shortcut: KeyboardShortcut
    let isRecording: Bool
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.accentBlue)
                .frame(width: 26)

            Text(LocalizedStringKey(shortcut.action.displayName))
                .font(.system(size: 13, weight: .medium))

            Spacer()

            if isRecording {
                Text("Press keys…")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.accentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.accentBlue, lineWidth: 1.5)
                    )
            } else {
                KeycapLabel(text: shortcut.displayName.isEmpty ? "—" : shortcut.displayName)
            }

            Button(action: onChange) {
                Text("Change")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Card(highlighted: isRecording))
    }

    private var iconName: String {
        switch shortcut.action {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .fullScreen: return "rectangle.fill"
        case .center: return "rectangle.center.inset.filled"
        default: return "rectangle"
        }
    }
}

struct KeycapLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Layouts

struct LayoutsView: View {
    @ObservedObject var viewModel: PanevoViewModel
    @State private var newLayoutName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    title: "Layouts",
                    subtitle: "Save your current window arrangement and restore it anytime"
                )

                SectionLabel(text: "Save Current Layout", icon: "camera.viewfinder")

                HStack(spacing: 10) {
                    TextField("Layout name (e.g. Coding)", text: $newLayoutName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 280)

                    Button(action: {
                        viewModel.saveCurrentLayout(named: newLayoutName)
                        newLayoutName = ""
                    }) {
                        Label("Save Layout", systemImage: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("Captures the position and size of every open window. Apply later to restore them exactly.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                if !viewModel.layoutProfiles.isEmpty {
                    SectionLabel(text: "Saved Profiles", icon: "bookmark.fill")

                    VStack(spacing: 8) {
                        ForEach(viewModel.layoutProfiles) { profile in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(profile.windowLayouts.count) windows")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Apply") {
                                    viewModel.applyLayoutProfile(profile)
                                }
                                .buttonStyle(.bordered)

                                Button(action: {
                                    viewModel.deleteLayoutProfile(profile)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Card())
                        }
                    }
                }
            }
            .padding(28)
        }
    }
}

// MARK: - Rules

struct RulesPaneView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var selectedPID: pid_t = 0
    @State private var selectedPosition: WindowPosition = .leftHalf
    @State private var ignoredAppID = ""

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    title: "Rules",
                    subtitle: "App-specific snap rules and ignore list"
                )

                SectionLabel(text: "App Rules", icon: "app.badge.checkmark")

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Picker("App", selection: $selectedPID) {
                            Text("Select app…").tag(pid_t(0))
                            ForEach(runningApps, id: \.processIdentifier) { app in
                                Text(app.localizedName ?? app.bundleIdentifier ?? "?")
                                    .tag(app.processIdentifier)
                            }
                        }
                        .frame(maxWidth: 260)

                        Picker("Position", selection: $selectedPosition) {
                            ForEach(WindowPosition.allCases, id: \.self) { pos in
                                Text(LocalizedStringKey(pos.displayName)).tag(pos)
                            }
                        }
                        .frame(maxWidth: 200)

                        Button("Add Rule") {
                            guard let app = runningApps.first(where: { $0.processIdentifier == selectedPID }),
                                  let bundleID = app.bundleIdentifier else { return }
                            settings.saveAppRule(AppRule(
                                bundleIdentifier: bundleID,
                                applicationName: app.localizedName ?? bundleID,
                                position: selectedPosition
                            ))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedPID == 0)
                    }

                    Text("When the app becomes frontmost, Panevo snaps its window to the chosen position.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    ForEach(settings.appRules) { rule in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.applicationName)
                                    .font(.system(size: 13, weight: .medium))
                                Text("\(rule.bundleIdentifier) → \(rule.position.displayName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { enabled in
                                    var updated = rule
                                    updated.isEnabled = enabled
                                    settings.saveAppRule(updated)
                                }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()

                            Button {
                                settings.deleteAppRule(rule)
                            } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Card())
                    }
                }

                SectionLabel(text: "Ignore List", icon: "eye.slash")

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Picker("Ignore", selection: $ignoredAppID) {
                            Text("Select app…").tag("")
                            ForEach(runningApps, id: \.processIdentifier) { app in
                                Text(app.localizedName ?? "?")
                                    .tag(app.bundleIdentifier ?? "")
                            }
                        }
                        .frame(maxWidth: 280)

                        Button("Add") {
                            settings.addIgnoredApp(ignoredAppID)
                            ignoredAppID = ""
                        }
                        .disabled(ignoredAppID.isEmpty)
                    }

                    Text("Ignored apps skip drag-to-snap and title-bar double-click.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    ForEach(settings.ignoredBundleIdentifiers, id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            Button {
                                settings.removeIgnoredApp(bundleID)
                            } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Card())
                    }
                }

                SectionLabel(text: "Display Profiles", icon: "display.2")

                DisplayProfilesSection()
            }
            .padding(28)
        }
    }
}

struct DisplayProfilesSection: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var displayCount = max(NSScreen.screens.count, 1)
    @State private var selectedProfileID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $settings.autoApplyDisplayProfiles) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-apply on display change")
                        .font(.system(size: 13, weight: .semibold))
                    Text("When you dock or undock, apply the layout bound to that display count")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Card())

            HStack(spacing: 10) {
                Stepper("Displays: \(displayCount)", value: $displayCount, in: 1...6)

                Picker("Layout", selection: $selectedProfileID) {
                    Text("Select layout…").tag(Optional<UUID>.none)
                    ForEach(settings.layoutProfiles) { profile in
                        Text(profile.displayName).tag(Optional(profile.id))
                    }
                }
                .frame(maxWidth: 220)

                Button("Bind") {
                    guard let id = selectedProfileID else { return }
                    settings.saveDisplayBinding(DisplayProfileBinding(
                        displayCount: displayCount,
                        layoutProfileID: id
                    ))
                }
                .disabled(selectedProfileID == nil || settings.layoutProfiles.isEmpty)
            }

            ForEach(settings.displayProfileBindings) { binding in
                let name = settings.layoutProfiles.first { $0.id == binding.layoutProfileID }?.displayName ?? "?"
                HStack {
                    Text("\(binding.displayCount) display(s) → \(name)")
                        .font(.system(size: 13))
                    Spacer()
                    Button {
                        settings.deleteDisplayBinding(binding)
                    } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Card())
            }
        }
    }
}

// MARK: - Settings

struct SettingsPaneView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var updater = UpdateChecker.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(
                    title: "Settings",
                    subtitle: "Tune Panevo to your workflow"
                )

                SectionLabel(text: "General", icon: "gearshape")

                VStack(spacing: 8) {
                    settingRow(title: "Launch at Login", subtitle: "Start Panevo automatically when you log in") {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    settingRow(title: "Snap Overlay", subtitle: "Show a preview overlay while dragging windows to screen edges") {
                        Toggle("", isOn: $settings.showOverlay)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    settingRow(title: "Title Bar Double-Click", subtitle: "Double-click a window title bar to maximize") {
                        Toggle("", isOn: $settings.titleBarDoubleClickEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    settingRow(title: "Modifier Drag Palette", subtitle: "Hold ⌃⌥ while dragging a window to open the snap palette") {
                        Toggle("", isOn: $settings.modifierDragEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }

                SectionLabel(text: "Snapping", icon: "rectangle.split.2x1")

                VStack(spacing: 8) {
                    settingRow(title: "Window Gap", subtitle: "Space between snapped windows") {
                        HStack(spacing: 10) {
                            Slider(value: $settings.windowGap, in: 0...24, step: 2)
                                .frame(width: 180)
                            Text("\(Int(settings.windowGap)) pt")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }

                    settingRow(title: "Edge Sensitivity", subtitle: "How close to the screen edge drag snapping triggers") {
                        HStack(spacing: 10) {
                            Slider(value: $settings.dragEdgeThreshold, in: 20...100, step: 5)
                                .frame(width: 180)
                            Text("\(Int(settings.dragEdgeThreshold)) pt")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }

                SectionLabel(text: "Animation", icon: "wand.and.rays")

                VStack(spacing: 8) {
                    settingRow(title: "Snap Animation", subtitle: "How windows move into place") {
                        Picker("", selection: $settings.animationStyle) {
                            Text("Instant").tag(SnapAnimationStyle.instant)
                            Text("Snappy").tag(SnapAnimationStyle.snappy)
                            Text("Smooth").tag(SnapAnimationStyle.smooth)
                            Text("Springy").tag(SnapAnimationStyle.springy)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)
                        .labelsHidden()
                    }
                }

                SectionLabel(text: "Backup", icon: "square.and.arrow.up.on.square")

                HStack(spacing: 12) {
                    Button("Export Settings") {
                        _ = settings.exportToFile()
                    }
                    .buttonStyle(.bordered)

                    Button("Import Settings") {
                        _ = settings.importFromFile()
                    }
                    .buttonStyle(.bordered)
                }

                SectionLabel(text: "Updates", icon: "arrow.triangle.2.circlepath")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version \(updater.currentVersion)")
                                .font(.system(size: 13, weight: .semibold))
                            if updater.isUpdateAvailable, let latest = updater.latestVersion {
                                Text("Update available: \(latest)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                            } else if updater.isChecking {
                                Text("Checking…")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else if let err = updater.lastError {
                                Text(err)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("You're up to date")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(updater.isUpdateAvailable ? "Download" : "Check") {
                            if updater.isUpdateAvailable, let url = updater.releaseURL {
                                NSWorkspace.shared.open(url)
                            } else {
                                updater.checkForUpdates()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(updater.isChecking)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Card())
                }

                SectionLabel(text: "Support", icon: "heart.fill")

                Button(action: {
                    if let url = URL(string: "https://buymeacoffee.com/bkrdmrcioglu") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 10) {
                        Text("☕")
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Buy Me a Coffee")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Panevo is free — support keeps it going!")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Card())
                }
                .buttonStyle(.plain)
            }
            .padding(28)
        }
    }

    private func settingRow<Control: View>(title: LocalizedStringKey, subtitle: LocalizedStringKey, @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Card())
    }
}

struct PresetCard: View {
    let preset: PresetLayout
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(Color.accentBlue)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isHovering ? Color.accentBlue : .secondary.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(preset.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Card(highlighted: isHovering))
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Shared styles

struct Card: View {
    var highlighted: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.primary.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        highlighted ? Color.accentBlue.opacity(0.5) : Color.primary.opacity(0.07),
                        lineWidth: 1
                    )
            )
    }
}

extension Color {
    static let accentBlue = Color(red: 0.35, green: 0.47, blue: 0.98)
    static let accentPurple = Color(red: 0.62, green: 0.36, blue: 0.95)
}
