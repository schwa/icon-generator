# icon-generator

A Swift CLI tool that generates squircle icons with customizable labels and center content.

## Overview

Renders a squircle (rounded rectangle with continuous corners) to PNG using SwiftUI's `ImageRenderer` and `Canvas`. Supports overlaying labels and center content with text, images, or SF Symbols.

## Usage

```bash
# Single PNG
icon-generator --background "#3366FF" -o icon.png

# App Icon Set for iOS
icon-generator -o AppIcon.appiconset --platform ios --background "#3366FF"

# App Icon Set for macOS
icon-generator -o AppIcon.appiconset --platform macos --center "sf:swift" --center-color "#FFFFFF"

# From JSON config
icon-generator --config config.json

# Kitchen sink demo (all features)
icon-generator --kitchen-sink -o demo.png
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-c, --config` | - | Path to JSON configuration file |
| `--background` | `white` | Background color or gradient |
| `--random` | - | Generate random icon configuration |
| `--kitchen-sink` | - | Generate demo icon using all features |
| `--dump-config` | - | Output resolved config as JSON (no image) |
| `-o, --output` | `icon.png` | Output file path (use `.appiconset` for Xcode asset) |
| `--size` | `1024` | Image size in pixels (single PNG only) |
| `--corner-style` | `squircle` | Corner style: `none`, `rounded`, or `squircle` |
| `--corner-radius` | `0.2237` | Corner radius ratio (0.0-0.5) |
| `--platform` | `ios` | App icon platform: `ios`, `macos`, `watchos`, `universal` |
| `--label` | - | Label specification (repeatable) |
| `--center` | - | Center content |
| `--center-color` | `black` | Center content color (CSS format) |
| `--center-size` | `0.5` | Center content size ratio (0.0-1.0) |
| `--center-align` | `typographic` | Alignment mode: `visual` or `typographic` |
| `--center-anchor` | `center` | Vertical anchor: `baseline`, `cap`, or `center` |
| `--center-y-offset` | `0` | Vertical offset ratio (-1.0 to 1.0, positive = up) |
| `--center-rotation` | `0` | Center content rotation in degrees (positive = clockwise) |

### Corner Styles

- `none` - Square corners (no rounding)
- `rounded` - Standard rounded corners (circular arcs)
- `squircle` - Continuous/superellipse corners (iOS-style, default)

### App Icon Platforms

When output path ends with `.appiconset`, generates an Xcode asset catalog icon set:

| Platform | Sizes Generated |
|----------|-----------------|
| `ios` | 1024px |
| `macos` | 16, 32, 64, 128, 256, 512, 1024px |
| `watchos` | 1024px |
| `universal` | iOS + macOS combined |

CLI arguments override config file values.

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
--label "topRight:sf:star.fill:#FFD700:#FFF:norotate"  # keeps content upright
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

**Alignment options:**
```bash
# Visual centering (based on glyph bounding box - best for single characters)
--center "Ə" --center-align visual

# Anchor at cap height
--center "text" --center-anchor cap

# Fine-tune with proportional offset
--center "ə" --center-y-offset 0.15

# Rotate center content 45 degrees clockwise
--center "sf:arrow.up" --center-rotation 45
```

### Gradient Backgrounds

```bash
# Linear gradient
--background "linear-gradient(to bottom, red, blue)"
--background "linear-gradient(45deg, orange, purple)"

# Radial gradient
--background "radial-gradient(#FFCC00, #FF6600)"

# Angular/conic gradient
--background "angular-gradient(red, orange, yellow, green, blue, purple, red)"
```

### JSON Configuration File

All options can be specified in a JSON file with `--config`:

```json
{
  "background": "#3366FF",
  "output": "icon.png",
  "size": 1024,
  "corner-style": "squircle",
  "corner-radius": 0.2237,
  "labels": [
    {"position": "topRight", "content": "BETA", "background-color": "#FF0000", "foreground-color": "#FFFFFF"},
    {"position": "pillCenter", "content": "sf:star.fill", "foreground-color": "#FFD700"}
  ],
  "center": {
    "content": "sf:swift",
    "color": "#FFFFFF",
    "size": 0.5
  }
}
```

**JSON Keys:**
- `background`: Background color (hex)
- `output`: Output file path (use `.appiconset` for Xcode asset)
- `size`: Image size in pixels (single PNG only)
- `corner-style`: Corner style (`none`, `rounded`, `squircle`)
- `corner-radius`: Corner radius ratio
- `platform`: App icon platform (`ios`, `macos`, `watchos`, `universal`)
- `labels`: Array of label objects
  - `position`: Label position (same as CLI)
  - `content`: Content string (text, `@path`, or `sf:symbol`)
  - `background-color`: Optional background color (hex)
  - `foreground-color`: Optional foreground color (hex)
  - `rotate-content`: Optional boolean (default `true`), set `false` for upright diagonal labels
  - `rotation`: Optional rotation in degrees (positive = clockwise)
- `center`: Center content object
  - `content`: Content string
  - `color`: Optional color (hex)
  - `size`: Optional size ratio
  - `alignment`: Optional alignment mode (`visual`, `typographic`)
  - `anchor`: Optional vertical anchor (`baseline`, `cap`, `center`)
  - `y-offset`: Optional vertical offset ratio

## Architecture

```
Sources/icon-generator/
├── IconGenerator.swift   # CLI entry point (ArgumentParser)
├── SquircleView.swift    # SwiftUI Canvas rendering
├── Label.swift           # Label model types
├── LabelParser.swift     # CLI argument parsing for labels
├── Configuration.swift   # JSON config file parsing
├── CornerStyle.swift     # Corner style enum (none/rounded/squircle)
├── AppIconSet.swift      # Xcode .appiconset generation
└── CSSColor.swift        # CSS color parsing (hex, rgb, named colors)
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
