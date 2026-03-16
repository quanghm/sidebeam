# SideBeam

Native macOS/iOS PDF presenter console, inspired by [pdfpc](https://pdfpc.github.io/). Built with SwiftUI and PDFKit.

Automatically splits wide Beamer pages (produced by `\setbeameroption{show notes on second screen=right}`) into slide and notes halves.

## Features

- **Presenter window**: current slide, next slide preview, rendered notes, elapsed timer (orange pill)
- **Projector window**: fullscreen on external display, or windowed on single screen
- **Beamer page splitting**: auto-detects wide pages and splits slide/notes halves
- **Welcome screen** with file picker and recent files (hotkeys `1`-`9`, `0`)
- **Keyboard-driven** navigation with vim-style bindings
- **Key bindings help overlay** (`h` to toggle, `Esc` to close)
- **Light/dark mode** support — adapts to system appearance
- **App icon** with dark/light variants
- **SwiftUI views** — cross-platform, portable to iPad

## Requirements

- macOS 14+ / iOS 17+
- Swift 5.9+

## Install

### Homebrew (recommended)

```bash
brew tap quanghm/sidebeam
brew install --cask sidebeam
```

### Manual

Download the latest `.app` from [Releases](https://github.com/quanghm/sidebeam/releases), unzip, and run:

```bash
xattr -cr SideBeam.app   # remove quarantine on first run
```

## Build & Run

```bash
swift build
swift run SideBeam presentation.pdf
```

Or without arguments to open a file picker:

```bash
swift run SideBeam
```

To build a `.app` bundle:

```bash
bash scripts/build-app.sh
open .build/SideBeam.app
```

## Key Bindings

### Presenting

| Key | Action |
|---|---|
| `→` `↓` `Space` `PgDn` `l` | Next slide |
| `←` `↑` `PgUp` `k` | Previous slide |
| `Home` | First slide |
| `End` | Last slide |
| `g` + number + `Enter` | Go to slide |
| `s` | Cycle split mode: none / right / left |
| `b` | Blank/unblank projector |
| `p` | Pause/resume timer |
| `r` | Reset timer |
| `f` | Toggle projector fullscreen |
| `h` | Toggle key bindings help |
| `⌘W` | Close presentation |
| `Esc` | Close help / cancel go-to |
| `q` | Quit |

### Welcome Screen

| Key | Action |
|---|---|
| `1`-`9`, `0` | Open recent file (1st through 10th) |
| `⌘O` | Open file picker |
| `⌘W` | Quit |

## Architecture

```
Sources/SideBeam/
├── SideBeamApp.swift   # SwiftUI App + AppKit window/keyboard managers (macOS)
├── MainView.swift          # Persistent container: switches between welcome/presenter
├── SlideManager.swift      # @Observable: PDF loading, navigation, split logic
├── SlideView.swift         # SwiftUI Canvas: PDF page rendering with crop
├── PresenterView.swift     # SwiftUI: current slide, next, notes, timer
├── ProjectorView.swift     # SwiftUI: fullscreen slide for projector
├── WelcomeView.swift       # SwiftUI: file picker + recent files
├── RecentFiles.swift       # LRU cache of 10 recent files (UserDefaults)
├── KeyBindingsView.swift   # SwiftUI: help overlay
├── AboutView.swift         # SwiftUI: about dialog
└── Info.plist              # App bundle metadata
```

All views are SwiftUI and cross-platform (macOS + iOS). Window management and keyboard handling use AppKit on macOS for reliability.

## iPad Support (beta)

- **External display** — auto-detects AirPlay/USB-C connected screens for projector output
- **Hardware keyboard** — same shortcuts as macOS (arrows, k/l, s, b, h)
- **Swipe gestures** — swipe left/right to navigate slides
- **Touch navigation** — prev/next buttons in bottom bar
- **Close button** — return to welcome screen
- **Recent files** — persisted with security-scoped bookmarks

Build with Xcode — select iPad target and run (⌘R).

## Roadmap (Pro)

See [SideBeam Pro](https://github.com/quanghm/sidebeam-pro) for premium features:
- Countdown timer with alerts
- Sidecar markdown notes
- Cloud integration (Google Drive / OneDrive)
- Slide annotations
- Localization

## Beamer Setup

Add to your LaTeX preamble:

```latex
\usepackage{pgfpages}
\setbeameroption{show notes on second screen=right}
```

This produces wide PDF pages with the slide on the left and notes on the right. SideBeam detects this automatically.
