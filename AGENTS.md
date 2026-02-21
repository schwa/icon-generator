# icon-generator

A Swift CLI tool that generates squircle icons with customizable labels and center content.

## Overview

Renders a squircle (rounded rectangle with continuous corners) to PNG using SwiftUI's `ImageRenderer` and `Canvas`. Supports overlaying labels and center content with text, images, or SF Symbols.

## Usage

```bash
icon-generator --background "#3366FF" -o icon.png
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--background` | `#FFFFFF` | Background color (hex) |
| `-o, --output` | `icon.png` | Output file path |
| `--size` | `1024` | Image size in pixels |
| `--corner-radius` | `0.2237` | Corner radius ratio (0.0-0.5) |
| `--label` | - | Label specification (repeatable) |
| `--center` | - | Center content |
| `--center-color` | `#000000` | Center content color (hex) |
| `--center-size` | `0.5` | Center content size ratio (0.0-1.0) |

### Labels

Format: `position:content[:backgroundColor[:foregroundColor]]`

**Positions:**
- Edge ribbons: `top`, `bottom`, `left`, `right`
- Corner ribbons: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`
- Bottom pills: `pillLeft`, `pillCenter`, `pillRight`

**Content types:**
- Text: `"BETA"` or `"v1.0"`
- Image: `@/path/to/image.png`
- SF Symbol: `sf:star.fill`

**Examples:**
```bash
--label "topRight:BETA"
--label "bottom:v1.0:#0000FF"
--label "pillCenter:NEW:#FF0000:#000000"
--label "topRight:sf:star.fill:#FFD700"
```

### Center Content

**Content types:**
- Text: `"A"` or `"Hello"`
- Image: `@/path/to/image.png`
- SF Symbol: `sf:swift`

**Examples:**
```bash
--center "A" --center-color "#FFFFFF" --center-size 0.6
--center "sf:swift" --center-color "#FFFFFF"
--center "@/path/to/logo.png" --center-size 0.4
```

## Architecture

```
Sources/icon-generator/
├── IconGenerator.swift   # CLI entry point (ArgumentParser)
├── SquircleView.swift    # SwiftUI Canvas rendering
├── Label.swift           # Label model types
├── LabelParser.swift     # CLI argument parsing for labels
└── Color+Hex.swift       # Hex color parsing extension
```

### Key Implementation Details

- Uses `Canvas` with `symbols` for efficient text/image rendering via attachments
- Labels are clipped to squircle shape using `context.clip(to:)`
- Center content is drawn before clipping so it's not affected by labels
- Diagonal ribbons use triangle paths with centroid-based text positioning
- SF Symbols use `Image(systemName:)` with system font sizing
- Async command (`AsyncParsableCommand`) to handle `@MainActor` rendering

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - CLI argument parsing

## Platform

- macOS 14+
- Swift 6
