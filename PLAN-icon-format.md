# Plan: Apple .icon Format Support

## Overview

Add support for generating Apple's `.icon` format used by Xcode's Icon Composer app (introduced in Xcode 26). This is a package/bundle format that contains layered icon compositions with advanced rendering features including appearance specializations (light/dark/tinted), visionOS glass effects, and multi-platform targeting.

## .icon Format Analysis

Based on analysis of the reference file and multiple GitHub samples:
- `/Users/schwa/Desktop/Icon.icon`
- `newmarcel/KeepingYouAwake` - Simple single-layer with appearance specializations
- `sbarex/SourceCodeSyntaxHighlight` - Multi-layer with position specializations
- `insidegui/AssetCatalogTinkerer` - Complex multi-group with all features
- `paulgessinger/swift-paperless` - Multiple layers with glass effects

### Bundle Structure
```
MyIcon.icon/
├── icon.json           # Main composition descriptor
└── Assets/             # Asset files (PNG, SVG)
    ├── icon.svg
    ├── background-light.png
    └── background-dark.png
```

### icon.json Schema (Comprehensive)

```json
{
  "color-space-for-untagged-svg-colors": "display-p3",
  
  "fill": "automatic" | "system-light" | "system-dark" | { "automatic-gradient": "..." } | { "solid": "..." },
  "fill-specializations": [
    { "value": "automatic" },
    { "appearance": "dark", "value": { "automatic-gradient": "srgb:R,G,B,A" } }
  ],
  
  "groups": [
    {
      "name": "Layer1",
      "hidden": false,
      "hidden-specializations": [{ "appearance": "tinted", "value": true }],
      
      "layers": [
        {
          "name": "layer-name",
          "image-name": "filename.svg",
          "image-name-specializations": [
            { "value": "light.png" },
            { "appearance": "dark", "value": "dark.png" }
          ],
          
          "fill": "automatic" | { "automatic-gradient": "..." } | { "solid": "..." },
          "fill-specializations": [...],
          
          "blend-mode": "normal",
          "blend-mode-specializations": [
            { "value": "overlay" },
            { "appearance": "dark", "value": "plus-lighter" }
          ],
          
          "opacity": 1.0,
          "opacity-specializations": [{ "appearance": "dark", "value": 0.5 }],
          
          "hidden": false,
          "hidden-specializations": [...],
          
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
      ],
      
      "shadow": { "kind": "neutral" | "layer-color", "opacity": 0.5 },
      "shadow-specializations": [...],
      
      "translucency": { "enabled": true, "value": 0.5 },
      "translucency-specializations": [...],
      
      "blur-material": 0.3 | null,
      
      "opacity": 1.0,
      "opacity-specializations": [...],
      
      "blend-mode-specializations": [...],
      
      "lighting": "combined" | "individual",
      "specular": true,
      "specular-specializations": [...]
    }
  ],
  
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared" | ["iOS", "macOS", "visionOS"]
  }
}
```

### Color Formats
- `"automatic"` - System automatic
- `"system-light"` / `"system-dark"` - System colors
- Extended sRGB: `"extended-srgb:R,G,B,A"` (floats, can exceed 0-1 for HDR)
- Extended Gray: `"extended-gray:L,A"` (luminance + alpha)
- Display P3: `"display-p3:R,G,B,A"`
- sRGB: `"srgb:R,G,B,A"`
- Gray: `"gray:L,A"`

### Specialization Keys
- `appearance`: `"light"`, `"dark"`, `"tinted"`
- `idiom`: `"square"`, `"macOS"`, `"iOS"`, etc.

### Blend Modes
`normal`, `overlay`, `soft-light`, `hard-light`, `plus-lighter`, `darken`, `multiply`, etc.

---

## Library Architecture

### New Target: `IconComposerFormat`

A standalone library for reading and writing Apple .icon bundles.

```
Sources/IconComposerFormat/
├── IconDocument.swift           # Root document type
├── IconGroup.swift              # Group with layers
├── IconLayer.swift              # Layer configuration  
├── IconFill.swift               # Fill types (solid, gradient)
├── IconColor.swift              # Color parsing (extended-srgb, display-p3, etc.)
├── IconPosition.swift           # Position with scale/translation
├── IconShadow.swift             # Shadow configuration
├── IconTranslucency.swift       # Translucency settings
├── Specialization.swift         # Generic specialization wrapper
├── SupportedPlatforms.swift     # Platform targeting
├── BlendMode.swift              # Blend mode enum
├── IconBundle.swift             # Bundle reading/writing
└── IconBundleError.swift        # Error types
```

### Package.swift Changes

```swift
// New library product
.library(name: "IconComposerFormat", targets: ["IconComposerFormat"]),

// New target (no dependencies - standalone)
.target(
    name: "IconComposerFormat"
),

// Test target
.testTarget(
    name: "IconComposerFormatTests",
    dependencies: ["IconComposerFormat"],
    resources: [
        .copy("Samples")  // Sample .icon bundles for testing
    ]
),

// Update icon-generator to depend on it
.executableTarget(
    name: "icon-generator",
    dependencies: [
        "IconRendering",
        "IconComposerFormat",  // NEW
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
),
```

---

## Implementation Plan

### Phase 1: Core Types (IconComposerFormat library)

**1.1 Color Parsing (`IconColor.swift`)**
```swift
public struct IconColor: Codable, Hashable, Sendable {
    public enum ColorSpace: String, Codable {
        case srgb = "srgb"
        case extendedSRGB = "extended-srgb"
        case displayP3 = "display-p3"
        case gray = "gray"
        case extendedGray = "extended-gray"
    }
    
    public var colorSpace: ColorSpace
    public var components: [Double]  // RGB(A) or L(A)
    
    /// Parse "extended-srgb:0.0,0.5,1.0,1.0"
    public init(parsing string: String) throws
    
    /// Convert to SwiftUI Color
    public var color: Color { get }
}
```

**1.2 Fill Types (`IconFill.swift`)**
```swift
public enum IconFill: Codable, Hashable, Sendable {
    case automatic
    case systemLight
    case systemDark
    case solid(IconColor)
    case automaticGradient(IconColor)
    
    // Custom decoding for: "automatic", "system-light", {"solid": "..."}, {"automatic-gradient": "..."}
}
```

**1.3 Specialization Wrapper (`Specialization.swift`)**
```swift
public struct Specialization<Value: Codable>: Codable, Sendable {
    public var value: Value
    public var appearance: Appearance?
    public var idiom: Idiom?
    
    public enum Appearance: String, Codable {
        case light, dark, tinted
    }
    
    public enum Idiom: String, Codable {
        case square, macOS, iOS, watchOS, visionOS
    }
}

// Convenience for properties that can be direct or specialized
public struct SpecializableProperty<Value: Codable>: Codable, Sendable {
    public var base: Value?
    public var specializations: [Specialization<Value>]?
    
    public func value(for appearance: Appearance?, idiom: Idiom?) -> Value?
}
```

**1.4 Position (`IconPosition.swift`)**
```swift
public struct IconPosition: Codable, Hashable, Sendable {
    public var scale: Double
    public var translationInPoints: [Double]  // [x, y]
    
    enum CodingKeys: String, CodingKey {
        case scale
        case translationInPoints = "translation-in-points"
    }
}
```

**1.5 Shadow (`IconShadow.swift`)**
```swift
public struct IconShadow: Codable, Hashable, Sendable {
    public enum Kind: String, Codable {
        case neutral = "neutral"
        case layerColor = "layer-color"
    }
    
    public var kind: Kind
    public var opacity: Double
}
```

**1.6 Translucency (`IconTranslucency.swift`)**
```swift
public struct IconTranslucency: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var value: Double
}
```

**1.7 Blend Mode (`BlendMode.swift`)**
```swift
public enum IconBlendMode: String, Codable, Hashable, Sendable {
    case normal
    case overlay
    case softLight = "soft-light"
    case hardLight = "hard-light"
    case plusLighter = "plus-lighter"
    case darken
    case multiply
    // ... etc
}
```

**1.8 Layer (`IconLayer.swift`)**
```swift
public struct IconLayer: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID = UUID()
    public var name: String?
    public var imageName: String?
    public var imageNameSpecializations: [Specialization<String>]?
    
    public var fill: IconFill?
    public var fillSpecializations: [Specialization<IconFill>]?
    
    public var blendMode: IconBlendMode?
    public var blendModeSpecializations: [Specialization<IconBlendMode>]?
    
    public var opacity: Double?
    public var opacitySpecializations: [Specialization<Double>]?
    
    public var hidden: Bool?
    public var hiddenSpecializations: [Specialization<Bool>]?
    
    public var glass: Bool?
    public var glassSpecializations: [Specialization<Bool>]?
    
    public var position: IconPosition?
    public var positionSpecializations: [Specialization<IconPosition>]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case imageName = "image-name"
        case imageNameSpecializations = "image-name-specializations"
        // ... etc
    }
}
```

**1.9 Group (`IconGroup.swift`)**
```swift
public struct IconGroup: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID = UUID()
    public var name: String?
    public var layers: [IconLayer]
    
    public var hidden: Bool?
    public var hiddenSpecializations: [Specialization<Bool>]?
    
    public var shadow: IconShadow?
    public var shadowSpecializations: [Specialization<IconShadow>]?
    
    public var translucency: IconTranslucency?
    public var translucencySpecializations: [Specialization<IconTranslucency>]?
    
    public var blurMaterial: Double?  // null = disabled
    
    public var opacity: Double?
    public var opacitySpecializations: [Specialization<Double>]?
    
    public var blendModeSpecializations: [Specialization<IconBlendMode>]?
    
    public var lighting: Lighting?
    public var specular: Bool?
    public var specularSpecializations: [Specialization<Bool>]?
    
    public enum Lighting: String, Codable {
        case combined, individual
    }
}
```

**1.10 Supported Platforms (`SupportedPlatforms.swift`)**
```swift
public struct SupportedPlatforms: Codable, Hashable, Sendable {
    public var circles: [String]?  // e.g., ["watchOS"]
    public var squares: SquaresPlatform?
    
    public enum SquaresPlatform: Codable, Hashable, Sendable {
        case shared
        case platforms([String])
        
        // Custom coding for "shared" string or ["iOS", "macOS"] array
    }
}
```

**1.11 Document (`IconDocument.swift`)**
```swift
public struct IconDocument: Codable, Hashable, Sendable {
    public var colorSpaceForUntaggedSVGColors: String?
    
    public var fill: IconFill?
    public var fillSpecializations: [Specialization<IconFill>]?
    
    public var groups: [IconGroup]
    public var supportedPlatforms: SupportedPlatforms?
    
    enum CodingKeys: String, CodingKey {
        case colorSpaceForUntaggedSVGColors = "color-space-for-untagged-svg-colors"
        case fill
        case fillSpecializations = "fill-specializations"
        case groups
        case supportedPlatforms = "supported-platforms"
    }
}
```

**1.12 Bundle I/O (`IconBundle.swift`)**
```swift
public struct IconBundle {
    public var document: IconDocument
    public var assets: [String: Data]  // filename -> data
    
    /// Read from .icon bundle path
    public init(contentsOf url: URL) throws
    
    /// Write to .icon bundle path
    public func write(to url: URL) throws
    
    /// Create new empty bundle
    public init(document: IconDocument = IconDocument(groups: []))
    
    /// Add asset (PNG or SVG data)
    public mutating func addAsset(name: String, data: Data)
    
    /// Get asset data
    public func asset(named: String) -> Data?
}
```

### Phase 2: Integration with icon-generator

**2.1 Update IconGenerator.swift**
```swift
// Detect .icon output
let isIconBundle = resolvedOutput.hasSuffix(".icon")

if isIconBundle {
    try generateIconBundle(...)
}
```

**2.2 New generation function**
```swift
func generateIconBundle(
    at path: String,
    background: Background,
    labels: [IconLabel],
    centerContent: CenterContent?,
    platforms: SupportedPlatforms?,
    translucency: IconTranslucency?,
    shadow: IconShadow?
) throws {
    var bundle = IconBundle()
    
    // Convert background to IconFill
    bundle.document.fill = convertToIconFill(background)
    
    // Create group with layers
    var group = IconGroup(layers: [])
    
    // Render center content as SVG, add to assets
    if let center = centerContent {
        let svg = renderCenterContentSVG(center)
        bundle.addAsset(name: "center.svg", data: svg)
        group.layers.append(IconLayer(name: "center", imageName: "center.svg"))
    }
    
    // Render labels as SVG layers
    for (i, label) in labels.enumerated() {
        let svg = renderLabelSVG(label)
        let name = "label-\(i).svg"
        bundle.addAsset(name: name, data: svg)
        group.layers.append(IconLayer(name: label.position.rawValue, imageName: name))
    }
    
    group.shadow = shadow
    group.translucency = translucency
    bundle.document.groups = [group]
    bundle.document.supportedPlatforms = platforms
    
    try bundle.write(to: URL(fileURLWithPath: path))
}
```

**2.3 New CLI options**
```
--format icon              Force .icon bundle output
--translucency <value>     Enable translucency (0.0-1.0)
--shadow <kind>            Add shadow (neutral/layer-color)
--glass                    Enable glass effect
--icon-platforms <list>    Target platforms (ios,macos,visionos,watchos)
```

### Phase 3: Configuration Support

**Update Configuration.swift**
```swift
struct IconConfiguration: Codable {
    // Existing...
    
    // New .icon-specific
    var translucency: IconTranslucencyConfig?
    var shadow: IconShadowConfig?
    var glass: Bool?
    var iconPlatforms: IconPlatformsConfig?
}
```

---

## File Changes Summary

| File | Change |
|------|--------|
| `Package.swift` | Add `IconComposerFormat` library target |
| `Sources/IconComposerFormat/*.swift` | **NEW** - All format types |
| `Tests/IconComposerFormatTests/` | **NEW** - Unit tests |
| `Tests/IconComposerFormatTests/Samples/` | **NEW** - Sample .icon bundles |
| `Sources/icon-generator/IconGenerator.swift` | Add .icon output support |
| `Sources/icon-generator/Configuration.swift` | Add .icon config fields |
| `AGENTS.md` | Document .icon format support |

---

## CLI Usage (Target)

```bash
# Generate .icon bundle (auto-detect from extension)
icon-generator --background "#3366FF" -o MyApp.icon

# With visionOS features
icon-generator --background "#3366FF" -o MyApp.icon \
    --translucency 0.5 \
    --shadow neutral \
    --glass

# Specify target platforms
icon-generator --background "#3366FF" -o MyApp.icon \
    --icon-platforms ios,visionos,watchos

# From config file
icon-generator --config app-icon.json -o MyApp.icon
```

---

## Testing Strategy

1. **Unit tests** - JSON serialization round-trips for all types
2. **Sample parsing** - Parse downloaded GitHub samples
3. **Integration tests** - Generate .icon, verify structure
4. **Visual validation** - Open generated .icon in Icon Composer

### Test Resources
Download and include these samples:
- `KeepingYouAwake` - Simple with appearance specializations
- `SourceCodeSyntaxHighlight` - Position specializations  
- `AssetCatalogTinkerer` - Complex multi-group
- `swift-paperless` - Glass effects

---

## Timeline Estimate

| Phase | Effort |
|-------|--------|
| Phase 1: Core Types | 4-5 hours |
| Phase 2: CLI Integration | 2-3 hours |
| Phase 3: Configuration | 1-2 hours |
| Testing & Polish | 2-3 hours |

**Total: ~10-13 hours**

---

## Open Questions

1. Should `IconComposerFormat` have any dependencies, or stay fully standalone?
2. Do we want to support reading existing .icon bundles and modifying them?
3. Should we render assets as SVG or PNG in the generated bundle?
4. How do we handle SF Symbols in .icon format? (Icon Composer uses SVG exports)
5. Should we add a `--import-icon` flag to read an existing .icon and dump config?
