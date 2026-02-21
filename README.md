# icon-generator

A Swift CLI tool for generating app icons with squircle shapes, labels, and SF Symbols. Outputs single PNGs or complete Xcode `.appiconset` bundles.

## Installation

```bash
swift build -c release
cp .build/release/icon-generator /usr/local/bin/
```

## Quick Start

```bash
# Simple icon
icon-generator --background "#007AFF" -o icon.png

# With SF Symbol
icon-generator --background "#F05138" --center "sf:swift" --center-color "#FFF" -o swift.png

# iOS app icon set
icon-generator -o AppIcon.appiconset --platform ios --background "#5856D6" --center "sf:star.fill" --center-color "#FFD700"

# macOS app icon set (all sizes)
icon-generator -o AppIcon.appiconset --platform macos --background "#34C759" --center "sf:leaf.fill" --center-color "#FFF"
```

## Examples

### Basic Icons

```bash
# Solid color
icon-generator --background "#FF3B30" -o red.png

# With text
icon-generator --background "#007AFF" --center "A" --center-color "#FFF" -o letter.png

# With SF Symbol
icon-generator --background "#5856D6" --center "sf:heart.fill" --center-color "#FFF" -o heart.png

# Large symbol
icon-generator --background "#FF9500" --center "sf:flame.fill" --center-color "#FFF" --center-size 0.7 -o flame.png
```

### Corner Styles

```bash
# iOS-style squircle (default)
icon-generator --background "#007AFF" --corner-style squircle -o squircle.png

# Standard rounded corners
icon-generator --background "#007AFF" --corner-style rounded -o rounded.png

# Square
icon-generator --background "#007AFF" --corner-style none -o square.png

# Custom radius
icon-generator --background "#007AFF" --corner-radius 0.4 -o round.png
```

### Labels - Corner Ribbons

```bash
# Beta badge
icon-generator --background "#007AFF" --center "sf:swift" --center-color "#FFF" \
  --label "topRight:BETA" -o beta.png

# With custom colors
icon-generator --background "#34C759" --center "sf:leaf.fill" --center-color "#FFF" \
  --label "topRight:NEW:#FFD700:#000" -o new.png

# SF Symbol in corner
icon-generator --background "#5856D6" --center "sf:star.fill" --center-color "#FFD700" \
  --label "topRight:sf:checkmark:#34C759:#FFF" -o verified.png

# Non-rotated symbol (stays upright)
icon-generator --background "#FF3B30" --center "sf:flame.fill" --center-color "#FFF" \
  --label "topRight:sf:star.fill:#FFD700:#000:norotate" -o star-upright.png
```

### Labels - Edge Ribbons

```bash
# Debug banner
icon-generator --background "#34C759" --center "sf:ant.fill" --center-color "#FFF" \
  --label "bottom:DEBUG:#000:#FFF" -o debug.png

# Top banner
icon-generator --background "#007AFF" --center "sf:cloud.fill" --center-color "#FFF" \
  --label "top:STAGING:#FF9500:#FFF" -o staging.png
```

### Labels - Pills

```bash
# Version pill
icon-generator --background "#5856D6" --center "sf:shippingbox.fill" --center-color "#FFF" \
  --label "pillCenter:v2.1.0:#000:#FFF" -o versioned.png

# Multiple pills
icon-generator --background "#007AFF" --center "sf:app.fill" --center-color "#FFF" \
  --label "pillLeft:iOS:#000:#FFF" \
  --label "pillRight:PRO:#FFD700:#000" -o multi-pill.png
```

### Multiple Labels

```bash
# Beta + version
icon-generator --background "#F05138" --center "sf:swift" --center-color "#FFF" \
  --label "topRight:BETA:#FF3B30:#FFF" \
  --label "pillCenter:v3.0:#000:#FFF" -o beta-versioned.png

# All corners
icon-generator --background "#FFF" \
  --label "topLeft:1:#FF3B30:#FFF" \
  --label "topRight:2:#007AFF:#FFF" \
  --label "bottomLeft:3:#34C759:#FFF" \
  --label "bottomRight:4:#FF9500:#FFF" -o corners.png
```

### App Icon Sets

```bash
# iOS (1024px)
icon-generator -o AppIcon.appiconset --platform ios \
  --background "#007AFF" --center "sf:star.fill" --center-color "#FFF"

# macOS (16-1024px, all sizes)
icon-generator -o AppIcon.appiconset --platform macos \
  --background "#F05138" --center "sf:swift" --center-color "#FFF"

# watchOS
icon-generator -o AppIcon.appiconset --platform watchos \
  --background "#FF3B30" --center "sf:heart.fill" --center-color "#FFF"

# Universal (iOS + macOS)
icon-generator -o AppIcon.appiconset --platform universal \
  --background "#5856D6" --center "sf:sparkles" --center-color "#FFD700"
```

### Using a Config File

Create `icon.json`:
```json
{
  "background": "#F05138",
  "output": "AppIcon.appiconset",
  "platform": "ios",
  "corner-style": "squircle",
  "corner-radius": 0.2237,
  "labels": [
    {"position": "topRight", "content": "BETA", "background-color": "#FF3B30"},
    {"position": "pillCenter", "content": "v2.0", "background-color": "#000"}
  ],
  "center": {
    "content": "sf:swift",
    "color": "#FFFFFF",
    "size": 0.5
  }
}
```

```bash
# Use config
icon-generator --config icon.json

# Override specific values
icon-generator --config icon.json --output different.png --background "#007AFF"
```

### Real-World Examples

```bash
# Swift package icon
icon-generator --background "#F05138" --center "sf:swift" --center-color "#FFF" \
  -o swift-package.png

# TestFlight build
icon-generator --background "#007AFF" --center "sf:airplane" --center-color "#FFF" \
  --label "topRight:TF:#FF9500:#FFF" \
  --label "pillCenter:build 142:#000:#FFF" -o testflight.png

# Debug build
icon-generator --background "#34C759" --center "sf:ladybug.fill" --center-color "#FFF" \
  --label "bottom:DEBUG:#000:#FFF" -o debug-build.png

# App Store release
icon-generator --background "#5856D6" --center "sf:star.fill" --center-color "#FFD700" \
  -o appstore.png

# Pro version
icon-generator --background "#1C1C1E" --center "sf:crown.fill" --center-color "#FFD700" \
  --label "pillRight:PRO:#FFD700:#000" -o pro.png

# Enterprise/internal
icon-generator --background "#8E8E93" --center "sf:building.2.fill" --center-color "#FFF" \
  --label "top:INTERNAL:#FF3B30:#FFF" -o internal.png

# Seasonal (holiday)
icon-generator --background "#FF3B30" --center "sf:gift.fill" --center-color "#FFF" \
  --label "topRight:sf:snowflake:#FFF:#007AFF:norotate" -o holiday.png
```

## Options Reference

| Option | Default | Description |
|--------|---------|-------------|
| `-c, --config` | - | JSON config file |
| `--background` | `white` | Background color (CSS format) |
| `-o, --output` | `icon.png` | Output path (`.png` or `.appiconset`) |
| `--size` | `1024` | Size in pixels (single PNG only) |
| `--corner-style` | `squircle` | `none`, `rounded`, `squircle` |
| `--corner-radius` | `0.2237` | Radius ratio (0.0-0.5) |
| `--platform` | `ios` | `ios`, `macos`, `watchos`, `universal` |
| `--center` | - | Center content (text, `sf:symbol`, `@path`) |
| `--center-color` | `black` | Center content color (CSS format) |
| `--center-size` | `0.5` | Center size ratio (0.0-1.0) |
| `--center-align` | `typographic` | `visual` (glyph bounds) or `typographic` (font metrics) |
| `--center-anchor` | `center` | `baseline`, `cap`, or `center` |
| `--center-y-offset` | `0` | Vertical offset ratio (-1.0 to 1.0, positive = up) |
| `--label` | - | Label spec (repeatable) |

### Center Alignment

For precise text/glyph positioning:

```bash
# Visual centering - centers based on actual glyph pixels (best for single characters)
icon-generator --center "Ə" --center-align visual -o schwa.png

# Anchor at baseline
icon-generator --center "Hello" --center-anchor baseline -o baseline.png

# Anchor at cap height (top of uppercase letters)
icon-generator --center "abc" --center-anchor cap -o cap.png

# Fine-tune with proportional offset (15% up)
icon-generator --center "ə" --center-y-offset 0.15 -o offset.png
```

### Label Format

```
position:content[:background[:foreground[:options]]]
```

**Positions:** `top`, `bottom`, `left`, `right`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `pillLeft`, `pillCenter`, `pillRight`

**Content:** Text, `sf:symbol.name`, or `@/path/to/image.png`

**Options:** `norotate` (keeps diagonal label content upright)

### Color Formats

Colors can be specified in multiple CSS-compatible formats:

```bash
# Hex (3, 6, or 8 digits)
--background "#F00"
--background "#FF0000"
--background "#FF000080"    # with alpha

# Named colors (140+ CSS colors)
--background red
--background steelblue
--background rebeccapurple

# RGB/RGBA functions
--background "rgb(255, 128, 0)"
--background "rgb(255 128 0)"
--background "rgb(100%, 50%, 0%)"
--background "rgba(255, 0, 0, 0.5)"
--background "rgba(0 128 255 / 0.8)"
```

## License

MIT
