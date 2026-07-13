# Contributing to Panevo

Thanks for your interest in contributing! 🎉
*Türkçe özet için [aşağıya bakın](#türkçe-özet).*

## Getting Started

### Requirements
- macOS 15 (Sequoia) or later
- Xcode 16+

### Build & Run
```bash
git clone https://github.com/bkrdmrcioglu/panevo.git
cd panevo
open Panevo.xcodeproj
```
Press `⌘R` in Xcode. On first launch, grant Accessibility permission
(System Settings → Privacy & Security → Accessibility) — required for window control.

> **Note:** App Sandbox must stay **disabled** (it already is). Sandboxed builds
> cannot control other apps' windows; this is why Panevo is not on the App Store.

## How to Contribute

1. **Fork** the repository and create a branch from `main`:
   `git checkout -b fix/short-description`
2. Make your changes.
3. **Test manually**: build, run, and exercise the affected flow
   (snap a real window with the hotkey/menu/drag — don't just compile).
4. Open a **Pull Request** against `main` with a clear description of
   what changed and how you tested it.

Small, focused PRs are reviewed much faster than big ones.

## Project Layout

| Directory | Purpose |
|---|---|
| `Panevo/Services/` | Core logic: `WindowManager` (snapping), `HotKeyManager` (global shortcuts), `AccessibilityManager` (AX API wrapper), `SettingsManager` (persistence) |
| `Panevo/Models/` | `WindowPosition`, `KeyboardShortcut`, `LayoutProfile` |
| `Panevo/ViewModels/` | `PanevoViewModel` (MVVM coordinator) |
| `Panevo/ContentView.swift` | Main SwiftUI UI |
| `Panevo/en.lproj`, `tr.lproj` | Localization |

## Code Style

- Swift, 4-space indentation, follow the existing style of the file you're editing
- No force unwraps in new code; handle failures with `guard`
- No external dependencies — Apple frameworks only
- UI strings must be localizable: add new strings to **both**
  `en.lproj/Localizable.strings` and `tr.lproj/Localizable.strings`

## Adding a Translation

Copy `Panevo/en.lproj/Localizable.strings` to `<lang>.lproj/`, translate the values
(not the keys), and add the language to `knownRegions` in the Xcode project.
Translation PRs are very welcome!

## Reporting Bugs / Requesting Features

Use the [issue templates](https://github.com/bkrdmrcioglu/panevo/issues/new/choose).
For bugs, always include your macOS version and steps to reproduce.

---

## Türkçe Özet

- Repo'yu **fork'la**, `main`'den branch aç, değişikliğini yap.
- **Elle test et**: derle, çalıştır, gerçek bir pencereyi kısayolla/menüyle yasla.
- `main`'e **Pull Request** aç; ne değiştirdiğini ve nasıl test ettiğini yaz.
- Yeni arayüz metinlerini hem `en.lproj` hem `tr.lproj` dosyalarına ekle.
- Harici bağımlılık ekleme; force unwrap (`!`) kullanma.
- Sandbox kapalı kalmalı — açılırsa pencere kontrolü çalışmaz.

Sorular için issue açabilirsin. Katkın için şimdiden teşekkürler! 🙌
