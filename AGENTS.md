# icon-generator

A Swift CLI tool that generates squircle icons with customizable labels and center content.

## Overview

Renders a squircle (rounded rectangle with continuous corners) to PNG using SwiftUI's `ImageRenderer` and `Canvas`. Supports overlaying labels and center content with text, images, or SF Symbols.

## Usage

```bash
# Single PNG
icon-generator --background "#3366FF" -o icon.png

# Single SVG
icon-generator --background "#3366FF" -o icon.svg

# App Icon Set for iOS
icon-generator -o AppIcon.appiconset --platform ios --background "#3366FF"

# App Icon Set for macOS
icon-generator -o AppIcon.appiconset --platform macos --layer "center; sf:swift; color=#FFFFFF"

# visionOS layered icon
icon-generator -o AppIcon.solidimagestack --background "#3366FF" --layer "center; sf:swift; color=#FFFFFF"

# From JSON/JSON5 config
icon-generator --config config.json

# Kitchen sink demo (all features)
icon-generator --kitchen-sink -o demo.png

# Icon Composer bundle (Xcode 26+)
icon-generator --background "#3366FF" -o MyApp.icon

# Icon Composer with visionOS features
icon-generator --background "#3366FF" -o MyApp.icon --translucency 0.5 --shadow neutral --glass
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `-c, --config` | - | Path to JSON/JSON5 configuration file |
| `--background` | `white` | Background color or gradient |
| `--random` | - | Generate random icon configuration |
| `--kitchen-sink` | - | Generate demo icon using all features |
| `--dump-config` | - | Output resolved config as JSON (no image) |
| `-o, --output` | `icon.png` | Output file path (`.appiconset`, `.solidimagestack`, `.icon`, `.svg`, `.png`) |
| `--size` | `1024` | Image size in pixels (single PNG only) |
| `--corner-style` | `squircle` | Corner style: `none`, `rounded`, or `squircle` |
| `--corner-radius` | `0.2237` | Corner radius ratio (0.0-0.5) |
| `--platform` | `ios` | App icon platform: `ios`, `macos`, `watchos`, `visionos`, `universal` |
| `--layer` | - | Layer specification (repeatable) |
| `--translucency` | - | Translucency for .icon output (0.0-1.0, visionOS) |
| `--shadow` | `neutral` | Shadow style for .icon: `neutral` or `layer-color` |
| `--glass` | - | Enable glass effect on center content (.icon only) |

### Corner Styles

- `none` - Square corners (no rounding)
- `rounded` - Standard rounded corners (circular arcs)
- `squircle` - Continuous/superellipse corners (iOS-style, default)

### App Icon Platforms

When output path ends with `.appiconset`, generates an Xcode asset catalog icon set:

| Platform | Format | Sizes Generated |
|----------|--------|------------------|
| `ios` | `.appiconset` | 1024px |
| `macos` | `.appiconset` | 16, 32, 64, 128, 256, 512, 1024px |
| `watchos` | `.appiconset` | 1024px |
| `visionos` | `.solidimagestack` | 1024px × 3 layers (Back, Middle, Front) |
| `universal` | `.appiconset` | iOS + macOS combined |

### visionOS Layered Icons (.solidimagestack)

When output path ends with `.solidimagestack`, generates a visionOS layered app icon:

```bash
icon-generator -o AppIcon.solidimagestack --background "#3366FF" --layer "center; sf:swift; color=#FFFFFF"
```

Layers are split automatically:
- **Back**: Background fill (gradient/color)
- **Middle**: Labels/ribbons
- **Front**: Center content

### Icon Composer Bundles (.icon)

When output path ends with `.icon`, generates an Xcode 26+ Icon Composer bundle:

```bash
icon-generator --background "#3366FF" -o MyApp.icon
icon-generator --background "#3366FF" -o MyApp.icon --translucency 0.7 --shadow layer-color --glass
```

| Option | Description |
|--------|-------------|
| `--translucency <value>` | Enable visionOS translucency (0.0-1.0) |
| `--shadow <style>` | Shadow style: `neutral` (default) or `layer-color` |
| `--glass` | Enable glass effect on center content |

CLI arguments override config file values.

### Layers

Format: `position; content[; key=value...]`

**Positions:**
- `center` - Center content
- Edge ribbons: `top`, `bottom`, `left`, `right`
- Corner ribbons: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`
- Bottom pills: `pillLeft`, `pillCenter`, `pillRight`

**Content types:**
- Text: `"BETA"` or `"v1.0"`
- Image: `@/path/to/image.png`
- SF Symbol: `sf:star.fill`

**Options (key=value):**
- `color` or `fg` - Foreground color
- `bg` - Background color (labels only)
- `size` - Size ratio 0.0-1.0 (center only)
- `align` - `visual` or `typographic` (center only)
- `anchor` - `baseline`, `cap`, or `center` (center only)
- `y-offset` - Vertical offset ratio (center only)
- `rotation` - Rotation in degrees
- `norotate` - Don't rotate content (diagonal labels)

**Examples:**
```bash
# Center content
--layer "center; sf:swift; color=#FFFFFF; size=0.5"
--layer "center; A; color=#FFFFFF; size=0.6"
--layer "center; @/path/to/logo.png; size=0.4"

# Labels
--layer "topRight; BETA; bg=#FF0000"
--layer "bottom; v1.0; bg=#0000FF"
--layer "pillCenter; NEW; bg=#FF0000; fg=#000000"
--layer "topRight; sf:star.fill; bg=#FFD700; norotate"
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
  "background": {"type": "linear", "colors": ["#667eea", "#764ba2"], "angle": 135},
  "output": "icon.png",
  "size": 1024,
  "corner-style": "squircle",
  "corner-radius": 0.2237,
  "layers": [
    {"position": "center", "symbol": "swift", "color": "#FFFFFF", "size": 0.5},
    {"position": "topRight", "text": "BETA", "background-color": "#FF0000"},
    {"position": "pillCenter", "symbol": "star.fill", "foreground-color": "#FFD700"}
  ]
}
```

**JSON Keys:**
- `background`: Solid color string or gradient object
- `output`: Output file path (use `.appiconset` for Xcode asset)
- `size`: Image size in pixels (single PNG only)
- `corner-style`: Corner style (`none`, `rounded`, `squircle`)
- `corner-radius`: Corner radius ratio
- `platform`: App icon platform (`ios`, `macos`, `watchos`, `universal`)
- `layers`: Array of layer objects
  - `position`: `center` or label position
  - `text`, `symbol`, or `image`: Content (use one)
  - `color` or `foreground-color`: Text/symbol color
  - `background-color`: Background (labels only, can be gradient)
  - `size`: Size ratio 0.0-1.0 (center only)
  - `rotate-content`: Boolean (default `true`)
  - `rotation`: Degrees (positive = clockwise)

## Architecture

```
Sources/icon-generator/
├── IconGenerator.swift            # CLI entry point (ArgumentParser)
├── IconBundleGenerator.swift      # .icon bundle generation
├── SolidImageStackGenerator.swift # visionOS .solidimagestack generation
├── Configuration.swift            # JSON config file parsing
├── AppIconSet.swift               # Xcode .appiconset generation
└── LayerParser.swift              # CLI argument parsing for layers

Sources/IconRendering/        # Core rendering library
├── SquircleView.swift        # SwiftUI Canvas rendering
├── Label.swift               # Label model types
├── CornerStyle.swift         # Corner style enum
└── CSSColor.swift            # CSS color parsing

Sources/IconComposerFormat/   # Apple .icon format library
├── IconBundle.swift          # Bundle write support
├── IconDocument.swift        # icon.json structure
├── IconGroup.swift           # Layer groups
├── IconLayer.swift           # Individual layers
├── IconFill.swift            # Fill types
├── IconColor.swift           # Color parsing (extended-srgb, display-p3, etc.)
└── ...                       # Supporting types
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
