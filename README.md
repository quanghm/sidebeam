# Beamer Viewer

Native macOS PDF presenter console, inspired by [pdfpc](https://pdfpc.github.io/). Built with Swift/AppKit and PDFKit.

Automatically splits wide Beamer pages (produced by `\setbeameroption{show notes on second screen=right}`) into slide and notes halves.

## Features

- **Presenter window**: current slide, next slide preview, rendered notes, elapsed timer
- **Projector window**: fullscreen on external display, or windowed on single screen
- **Beamer page splitting**: auto-detects wide pages and splits slide/notes halves
- **Keyboard-driven** navigation with vim-style bindings
- **Key bindings help overlay** (`h` to toggle)
- **Light/dark mode** support — adapts to macOS appearance

## Requirements

- macOS 13+
- Swift 5.9+

## Install

Download the latest `.app` from [Releases](https://github.com/quanghm/beamer-viewer/releases), unzip, and run:

```bash
xattr -cr BeamerViewer.app   # remove quarantine on first run
```

## Build & Run

```bash
swift build
swift run BeamerViewer presentation.pdf
```

Or without arguments to open a file picker:

```bash
swift run BeamerViewer
```

To build a `.app` bundle:

```bash
bash scripts/build-app.sh 0.0.2
open .build/BeamerViewer.app
```

## Key Bindings

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
| `Esc` `q` | Quit |

## TODO

- [ ] Sidecar `.notes.md` file support — per-slide Markdown notes rendered in the presenter view
- [ ] Markdown rendering for notes (rich text, lists, code blocks, emphasis)
- [ ] Fallback to sidecar notes when split mode is `none` (regular PDFs)
- [ ] App icon

## Beamer Setup

Add to your LaTeX preamble:

```latex
\usepackage{pgfpages}
\setbeameroption{show notes on second screen=right}
```

This produces wide PDF pages with the slide on the left and notes on the right. Beamer Viewer detects this automatically.
