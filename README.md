# Panevo

🇬🇧 English | **🇹🇷 [Türkçe](README.tr.md)**

**A modern, native window manager for macOS.**

Panevo is a lightweight menu bar app that lets you arrange your windows in seconds using keyboard shortcuts, the menu bar, or drag-to-edge snapping. Built entirely natively with Swift + SwiftUI + AppKit — zero external dependencies.

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Version](https://img.shields.io/badge/version-1.2-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)
[![Buy Me A Coffee](https://img.shields.io/badge/☕-Buy%20me%20a%20coffee-FFDD00)](https://buymeacoffee.com/bkrdmrcioglu)

---

## ✨ Features

### 🪟 Window Snapping (15 positions)
- Left / Right / Top / Bottom halves
- Four quarters (Top Left, Top Right, Bottom Left, Bottom Right)
- Thirds and two-thirds
- Maximize and Center
- **Cycling**: press the same half-snap shortcut again to cycle half → third → two thirds
- **Restore**: return a window to its pre-snap size and position
- **Window gaps**: keep an adjustable gutter (0–24 pt) between snapped windows

### ⌨️ System-wide Keyboard Shortcuts
Work in every app. Defaults:

| Shortcut | Action |
|---|---|
| ⌃⌥ ← | Left Half (→ ⅓ → ⅔) |
| ⌃⌥ → | Right Half (→ ⅓ → ⅔) |
| ⌃⌥ ↑ | Top Half |
| ⌃⌥ ↓ | Bottom Half |
| ⌃⌥ ↩ | Maximize |
| ⌃⌥ C | Center |
| ⌃⌥ ⌫ | Restore |
| ⌃⌥ N | Move to Next Display |
| ⌃⌥ P | Move to Previous Display |

Every action can be **rebound in-app** (Shortcuts → Change → press your combo). Any snap position — including quarters and thirds — can be given its own shortcut. Conflicts are detected automatically.

### 🖱️ Drag to Snap
Drag a window to a screen edge: a blue preview appears, release to snap. Corners snap to quarters. Edge sensitivity is adjustable, and it only triggers on real window drags.

### 📐 Layout Profiles
- **Save Current Layout**: captures the position and size of every open window
- **Apply**: restores the saved arrangement — launching missing apps if needed
- Profiles persist across restarts

### 📍 Menu Bar Native
No Dock icon — Panevo lives entirely in your menu bar with quick snap actions one click away.

### ⚙️ Settings
- Launch at Login
- Snap animation styles: Instant / Snappy / Smooth / Springy
- Window gap and edge sensitivity sliders
- Preview overlay toggle
- All settings persist

### 🌍 Languages
English and Turkish — follows your system language.

---

## 📥 Installation

**Homebrew** (recommended):
```bash
brew install --cask bkrdmrcioglu/tap/panevo
```

**Manual**: grab the latest DMG from [**Releases**](https://github.com/bkrdmrcioglu/panevo/releases), open it, and drag Panevo to Applications.

The app is **signed and notarized by Apple** — no security warnings, just open it.

> First launch: grant Accessibility permission in System Settings → Privacy & Security → Accessibility. This permission is required by all window managers to move other apps' windows.

### Why not on the App Store?
The App Store requires App Sandbox, and sandboxed apps cannot control other applications' windows — the entire point of a window manager. This is the same reason Rectangle isn't on the App Store either.

## 🔨 Building from Source

```bash
git clone https://github.com/bkrdmrcioglu/panevo.git
cd panevo
open Panevo.xcodeproj   # then ⌘R
```

Requires macOS 15+ and Xcode 16+.

## 🏗️ Architecture

```
Panevo/
├── App.swift                  # Entry point + AppDelegate (menu bar lifecycle)
├── ContentView.swift          # Main SwiftUI UI
├── Models/                    # WindowPosition, KeyboardShortcut, LayoutProfile…
├── Services/
│   ├── WindowManager          # Snapping orchestration, cycling, restore, gaps
│   ├── AccessibilityManager   # macOS Accessibility API wrapper
│   ├── HotKeyManager          # Global shortcuts (Carbon), live re-registration
│   ├── DisplayManager         # Multi-monitor tracking
│   ├── LayoutProfileManager   # Layout capture/restore
│   ├── SettingsManager        # UserDefaults persistence
│   └── StatusBarManager       # Menu bar item and menu
├── ViewModels/                # MVVM coordination
├── Views/                     # Snap overlay, preferences window
├── Utilities/                 # Extensions and helpers
└── en.lproj / tr.lproj        # Localization
```

**Patterns:** MVVM, dependency injection, service layer. **Dependencies:** none — Apple frameworks only (SwiftUI, AppKit, Carbon, Combine, ServiceManagement).

## 🔒 Privacy

- ❌ No network connections
- ❌ No data collection
- ✅ All settings stored locally

## 📝 Changelog

### 1.2
- Window gaps with adjustable size
- Shortcut assignment for **all** actions; in-app shortcut recording
- Corner drag zones (quarter snapping) + edge sensitivity setting
- Pure menu bar app — no Dock icon

### 1.1
- Restore (pre-snap frame), snap cycling (half → ⅓ → ⅔)
- Display-move shortcuts, layout profiles that launch missing apps
- App icon, drag-snap fixes, crash fix

### 1.0
- 15 snap positions, 6 global shortcuts, drag-to-edge snapping
- Layout profiles, menu bar quick actions, multi-monitor support
- English & Turkish UI

## ☕ Support

Panevo is free and open source. If it makes your day easier, you can [**buy me a coffee**](https://buymeacoffee.com/bkrdmrcioglu) — it keeps the project going!

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first, and use the [issue templates](https://github.com/bkrdmrcioglu/panevo/issues/new/choose) for bugs and feature requests.

## 📄 License

[MIT](LICENSE) — © 2026 Bekir Demircioglu

---

Built with ❤️ for macOS productivity.
