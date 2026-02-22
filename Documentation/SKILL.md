# icon-generator

CLI to generate app icons with squircles, gradients, and SF Symbols.

## Quick Start

```bash
# Build
swift build -c release

# Basic icon
icon-generator --background "#3366FF" -o icon.png

# With center symbol
icon-generator --background "#3366FF" --layer "center:sf:swift:color=#FFFFFF" -o icon.png

# Xcode asset catalog
icon-generator --background "#3366FF" -o AppIcon.appiconset --platform ios
```

## Output Formats

| Extension | Description |
|-----------|-------------|
| `.png` | Single PNG image |
| `.svg` | Single SVG image |
| `.appiconset` | Xcode asset catalog (all required sizes) |
| `.icon` | Xcode 26+ (macOS/iOS/visionOS 26) Icon Composer bundle |

## Layer Syntax

```
--layer "position:content[:key=value...]"
```

**Positions:** `center`, `top`, `bottom`, `left`, `right`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, `pillLeft`, `pillCenter`, `pillRight`

**Content:**
- Text: `"BETA"`, `"v1.0"`
- SF Symbol: `sf:star.fill`
- Image: `@/path/to/image.png`

**Common options:**
- `color=#FFFFFF` - Foreground color
- `bg=#FF0000` - Background color (labels)
- `size=0.5` - Size ratio (center only)

## Examples

```bash
# Gradient background
icon-generator --background "linear-gradient(45deg, #667eea, #764ba2)" -o icon.png

# Beta badge
icon-generator --background "#3366FF" --layer "topRight:BETA:bg=#FF0000" -o icon.png

# Multiple layers
icon-generator --background "#3366FF" \
  --layer "center:sf:swift:color=#FFFFFF:size=0.5" \
  --layer "topRight:BETA:bg=#FF0000" \
  -o icon.png

# macOS app icon set
icon-generator --background "#3366FF" -o AppIcon.appiconset --platform macos

# Icon Composer with visionOS features
icon-generator --background "#3366FF" -o App.icon --translucency 0.5 --glass
```

## JSON Config

For complex icons, use a JSON config file:

```bash
icon-generator --config icon.json
```

```json
{
  "background": {"type": "linear", "colors": ["#667eea", "#764ba2"], "angle": 135},
  "layers": [
    {"position": "center", "symbol": "swift", "color": "#FFFFFF", "size": 0.5},
    {"position": "topRight", "text": "BETA", "background-color": "#FF0000"}
  ]
}
```

## Key Options

| Option | Description |
|--------|-------------|
| `--background` | Color or gradient |
| `--layer` | Add layer (repeatable) |
| `--size` | Output size in pixels |
| `--corner-style` | `none`, `rounded`, `squircle` |
| `--platform` | `ios`, `macos`, `watchos`, `universal` |
| `--config` | JSON config file |
| `--dump-config` | Output resolved config as JSON |
| `--random` | Generate random icon |
| `--kitchen-sink` | Demo all features |

## Icon Composer Options (.icon)

| Option | Description |
|--------|-------------|
| `--translucency <0.0-1.0>` | visionOS translucency level |
| `--shadow <style>` | `neutral` (default) or `layer-color` |
| `--glass` | Enable glass effect on center content |
