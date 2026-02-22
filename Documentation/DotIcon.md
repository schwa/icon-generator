# Apple .icon Format Reference

The `.icon` format is a bundle format used by Xcode's Icon Composer app (introduced in Xcode 26) for creating layered icon compositions with advanced rendering features including appearance specializations (light/dark/tinted), visionOS glass effects, and multi-platform targeting.

## Bundle Structure

```
MyIcon.icon/
├── icon.json           # Main composition descriptor
└── Assets/             # Asset files (PNG, SVG)
    ├── icon.svg
    ├── background-light.png
    └── background-dark.png
```

## icon.json Schema

### Document Level

```json
{
  "color-space-for-untagged-svg-colors": "display-p3",
  
  "fill": "automatic",
  "fill-specializations": [
    { "value": "automatic" },
    { "appearance": "dark", "value": { "automatic-gradient": "srgb:0.5,0.5,0.5,1.0" } }
  ],
  
  "groups": [ ... ],
  
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `color-space-for-untagged-svg-colors` | string | Color space for SVGs without embedded profiles (e.g., `"display-p3"`) |
| `fill` | Fill | Background fill |
| `fill-specializations` | Specialization<Fill>[] | Per-appearance background fills |
| `groups` | Group[] | Layer groups (rendered back to front) |
| `supported-platforms` | SupportedPlatforms | Target platforms |

### Group Level

```json
{
  "name": "Layer1",
  "hidden": false,
  "hidden-specializations": [{ "appearance": "tinted", "value": true }],
  
  "layers": [ ... ],
  
  "shadow": { "kind": "neutral", "opacity": 0.5 },
  "shadow-specializations": [
    { "value": { "kind": "neutral", "opacity": 1 } },
    { "appearance": "dark", "value": { "kind": "layer-color", "opacity": 1 } }
  ],
  
  "translucency": { "enabled": true, "value": 0.5 },
  "translucency-specializations": [
    { "value": { "enabled": true, "value": 0.7 } },
    { "appearance": "dark", "value": { "enabled": true, "value": 0.3 } }
  ],
  
  "blur-material": 0.3,
  
  "opacity": 0.9,
  "opacity-specializations": [
    { "value": 1.0 },
    { "appearance": "dark", "value": 0.5 }
  ],
  
  "blend-mode-specializations": [
    { "value": "overlay" },
    { "appearance": "dark", "value": "plus-lighter" }
  ],
  
  "lighting": "combined",
  "specular": true,
  "specular-specializations": [
    { "value": false },
    { "appearance": "dark", "value": true }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string? | Group name (displayed in Icon Composer) |
| `hidden` | bool? | Whether group is hidden |
| `hidden-specializations` | Specialization<bool>[]? | Per-appearance hidden state |
| `layers` | Layer[] | Layers in this group |
| `shadow` | Shadow? | Shadow configuration |
| `shadow-specializations` | Specialization<Shadow>[]? | Per-appearance shadows |
| `translucency` | Translucency? | visionOS translucency |
| `translucency-specializations` | Specialization<Translucency>[]? | Per-appearance translucency |
| `blur-material` | double? | Blur material strength (null = disabled) |
| `opacity` | double? | Group opacity (0.0-1.0) |
| `opacity-specializations` | Specialization<double>[]? | Per-appearance opacity |
| `blend-mode-specializations` | Specialization<BlendMode>[]? | Per-appearance blend modes |
| `lighting` | string? | `"combined"` or `"individual"` |
| `specular` | bool? | Enable specular highlights |
| `specular-specializations` | Specialization<bool>[]? | Per-appearance specular |

### Layer Level

```json
{
  "name": "icon",
  "image-name": "icon.svg",
  "image-name-specializations": [
    { "value": "icon-light.png" },
    { "appearance": "dark", "value": "icon-dark.png" }
  ],
  
  "fill": "automatic",
  "fill-specializations": [
    { "value": "automatic" },
    { "appearance": "dark", "value": { "automatic-gradient": "display-p3:0.0,0.5,1.0,1.0" } }
  ],
  
  "blend-mode": "normal",
  "blend-mode-specializations": [
    { "value": "overlay" },
    { "appearance": "dark", "value": "plus-lighter" }
  ],
  
  "opacity": 1.0,
  "opacity-specializations": [{ "appearance": "dark", "value": 0.5 }],
  
  "hidden": false,
  "hidden-specializations": [{ "appearance": "tinted", "value": true }],
  
  "glass": true,
  "glass-specializations": [
    { "value": false },
    { "appearance": "dark", "value": true }
  ],
  
  "position": {
    "scale": 1.0,
    "translation-in-points": [0, 0]
  },
  "position-specializations": [
    { "idiom": "square", "value": { "scale": 1.25, "translation-in-points": [0, 0] } }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | string? | Layer name |
| `image-name` | string? | Asset filename (e.g., `"icon.svg"`) |
| `image-name-specializations` | Specialization<string>[]? | Per-appearance images |
| `fill` | Fill? | Layer fill override |
| `fill-specializations` | Specialization<Fill>[]? | Per-appearance fills |
| `blend-mode` | BlendMode? | Blend mode |
| `blend-mode-specializations` | Specialization<BlendMode>[]? | Per-appearance blend modes |
| `opacity` | double? | Layer opacity (0.0-1.0) |
| `opacity-specializations` | Specialization<double>[]? | Per-appearance opacity |
| `hidden` | bool? | Whether layer is hidden |
| `hidden-specializations` | Specialization<bool>[]? | Per-appearance hidden state |
| `glass` | bool? | Enable visionOS glass effect |
| `glass-specializations` | Specialization<bool>[]? | Per-appearance glass |
| `position` | Position? | Scale and translation |
| `position-specializations` | Specialization<Position>[]? | Per-idiom positioning |

## Types

### Fill

```json
// String values
"automatic"
"system-light"
"system-dark"

// Object values
{ "solid": "srgb:1.0,0.0,0.0,1.0" }
{ "automatic-gradient": "display-p3:0.0,0.5,1.0,1.0" }
```

### Color Formats

| Format | Example | Description |
|--------|---------|-------------|
| `srgb` | `"srgb:1.0,0.0,0.0,1.0"` | Standard RGB |
| `extended-srgb` | `"extended-srgb:1.2,0.0,0.0,1.0"` | Extended sRGB (HDR, values can exceed 0-1) |
| `display-p3` | `"display-p3:1.0,0.0,0.0,1.0"` | Display P3 wide gamut |
| `gray` | `"gray:0.5,1.0"` | Grayscale (luminance, alpha) |
| `extended-gray` | `"extended-gray:0.5,1.0"` | Extended grayscale |

### Shadow

```json
{
  "kind": "neutral",
  "opacity": 0.5
}
```

| Field | Values | Description |
|-------|--------|-------------|
| `kind` | `"neutral"`, `"layer-color"` | Shadow type |
| `opacity` | 0.0-1.0 | Shadow opacity |

### Translucency

```json
{
  "enabled": true,
  "value": 0.5
}
```

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | bool | Whether translucency is active |
| `value` | double | Translucency amount (0.0-1.0) |

### Position

```json
{
  "scale": 1.25,
  "translation-in-points": [0, 14]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `scale` | double | Scale factor (1.0 = original) |
| `translation-in-points` | [x, y] | Offset in points |

### BlendMode

Values: `normal`, `multiply`, `screen`, `overlay`, `darken`, `lighten`, `color-dodge`, `color-burn`, `soft-light`, `hard-light`, `difference`, `exclusion`, `hue`, `saturation`, `color`, `luminosity`, `plus-darker`, `plus-lighter`

### SupportedPlatforms

```json
{
  "circles": ["watchOS"],
  "squares": "shared"
}

// Or specific platforms
{
  "squares": ["iOS", "macOS", "visionOS"]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `circles` | string[]? | Circular icon platforms (e.g., watchOS) |
| `squares` | `"shared"` or string[] | Squircle icon platforms |

### Specialization

```json
{ "value": ... }
{ "appearance": "dark", "value": ... }
{ "appearance": "tinted", "value": ... }
{ "idiom": "square", "value": ... }
{ "idiom": "macOS", "value": ... }
```

| Field | Values | Description |
|-------|--------|-------------|
| `value` | any | The specialized value |
| `appearance` | `"light"`, `"dark"`, `"tinted"` | Appearance mode |
| `idiom` | `"square"`, `"macOS"`, `"iOS"`, `"watchOS"`, `"visionOS"` | Device idiom |

## Feature Coverage in icon-generator

### Supported via CLI

| Feature | CLI Flag | Example |
|---------|----------|---------|
| Background fill | `--background` | `--background "#3366FF"` |
| Shadow style | `--shadow` | `--shadow neutral`, `--shadow layer-color` |
| Translucency | `--translucency` | `--translucency 0.7` |
| Glass effect | `--glass` | `--glass` |
| Layers | `--layer` | `--layer "center:sf:swift:color=#FFFFFF"` |

### Supported in Types (not exposed via CLI)

- Fill specializations (light/dark/tinted variants)
- All blend modes
- Opacity (group and layer level)
- Position (scale and translation)
- Blur material
- Lighting modes
- Specular highlights
- Image name specializations
- Hidden states
- Platform targeting
- Color space configuration

### Not Yet Implemented

- Reading/importing existing .icon bundles
- Multiple groups
- Per-layer CLI configuration

## Sample Repositories

These GitHub repositories contain `.icon` files for reference:

| Repository | Path | Features |
|------------|------|----------|
| [newmarcel/KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) | `KeepingYouAwake/AppIcon.icon` | Appearance specializations |
| [insidegui/AssetCatalogTinkerer](https://github.com/insidegui/AssetCatalogTinkerer) | `Resources/AppIconV7.icon` | Multi-group, blur, lighting, specular |
| [paulgessinger/swift-paperless](https://github.com/paulgessinger/swift-paperless) | `swift-paperless/AppIcon.icon` | Glass effects, color space |
| [chrismaltby/gb-studio](https://github.com/chrismaltby/gb-studio) | `src/assets/app/icon/app_icon.icon` | |
| [root3nl/SupportApp](https://github.com/root3nl/SupportApp) | `src/Support/AppIcon.icon` | |
| [HabitRPG/habitica-ios](https://github.com/HabitRPG/habitica-ios) | `HabitRPG/AppIcons/habitica.icon` | |
| [PDF-Archiver/PDF-Archiver](https://github.com/PDF-Archiver/PDF-Archiver) | `Shared/Resources/AppIcon.icon` | |
| [zorgiepoo/Komet](https://github.com/zorgiepoo/Komet) | `Komet/KometAppIcon.icon` | |

## Example: Complete icon.json

```json
{
  "color-space-for-untagged-svg-colors": "display-p3",
  "fill": "system-light",
  "groups": [
    {
      "name": "Foreground",
      "layers": [
        {
          "name": "icon",
          "image-name": "icon.svg",
          "glass": true,
          "position": {
            "scale": 1.24,
            "translation-in-points": [0, 0]
          },
          "fill-specializations": [
            { "value": "automatic" },
            { "appearance": "dark", "value": { "automatic-gradient": "display-p3:0.0,0.5,1.0,1.0" } }
          ]
        }
      ],
      "shadow": { "kind": "neutral", "opacity": 0.5 },
      "translucency": { "enabled": true, "value": 0.5 },
      "lighting": "combined",
      "specular": true
    },
    {
      "name": "Background",
      "layers": [
        {
          "name": "background",
          "image-name-specializations": [
            { "value": "background-light.png" },
            { "appearance": "dark", "value": "background-dark.png" }
          ]
        }
      ],
      "shadow": { "kind": "neutral", "opacity": 0.5 },
      "translucency": { "enabled": false, "value": 0.5 }
    }
  ],
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  }
}
```
