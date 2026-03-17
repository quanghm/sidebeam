---
layout: page
title: Beamer Setup
---

## What is Beamer?

[Beamer](https://ctan.org/pkg/beamer) is a LaTeX document class for creating presentations. It can embed speaker notes alongside slides in the PDF output.

## Enable Notes

Add this to your LaTeX preamble:

```latex
\usepackage{pgfpages}
\setbeameroption{show notes on second screen=right}
```

This produces wide PDF pages with the slide on the left half and notes on the right half.

## Auto-Detection

SideBeam automatically detects wide pages (~2:1 aspect ratio) and splits them into slide and notes halves. No configuration needed — just open the PDF.

If detection is wrong, press **s** to cycle split modes manually:
- **none** — show full page
- **right** — notes on right (default)
- **left** — notes on left

## Adding Notes

Use `\note{}` in your Beamer source:

```latex
\begin{frame}{My Slide Title}
  \begin{itemize}
    \item First point
    \item Second point
  \end{itemize}

  \note{
    Remember to explain the timeline.
    Mention the budget constraints.
  }
\end{frame}
```

Notes appear in the presenter view but not on the projector.

## Notes on Every Slide

To add notes to every slide, you can use:

```latex
\setbeameroption{show notes on second screen=right}

% Optional: show note placeholders on slides without notes
\setbeamertemplate{note page}{
  \insertnote
}
```

## Regular PDFs

SideBeam works with any PDF — not just Beamer presentations. For regular PDFs, the presenter shows the full page with next slide preview. Split mode is set to **none** automatically.
