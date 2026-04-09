# ISSUES.md

---

## 1: Add more PNG vs SVG renderer comparison tests
status: new
priority: low
kind: enhancement
created: 2026-02-21T00:00:00Z

Currently we have a single basic squircle comparison test between PNG (CanvasIconRenderer) and SVG (SVGIconRenderer via WebKit rasterization). Should add more tests covering gradients, labels, center content, etc. to catch renderer divergence.

---

## 2: Add --icon-platforms CLI flag for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21T00:00:00Z

Allow specifying target platforms (ios, macos, visionos, watchos) for .icon bundles via CLI. Currently hardcoded to watchOS circles + shared squares.

---

## 3: Add --blur-material CLI flag for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21T00:00:00Z

Add CLI support for visionOS blur material effect (0.0-1.0 strength). The type already exists in IconComposerFormat.

---

## 4: Add .icon configuration support to JSON config files
status: new
priority: low
kind: feature
labels: icon-format, config
created: 2026-02-21T00:00:00Z

Allow specifying .icon-specific options (translucency, shadow, glass, blur-material, platforms) in JSON configuration files. Currently only CLI flags are supported.

---

## 5: Support appearance specializations for .icon output
status: new
priority: low
kind: feature
labels: icon-format
created: 2026-02-21T00:00:00Z

Allow generating .icon bundles with light/dark/tinted appearance variants. Would require rendering multiple SVG assets per layer and adding specialization entries. Types already support this in IconComposerFormat.

---

## 6: Add --import-icon flag to read existing .icon bundles
status: new
priority: low
kind: feature
labels: icon-format
created: 2026-02-21T00:00:00Z

Allow importing an existing .icon bundle and dumping its configuration, or using it as a base for modifications. Would require adding read support back to IconBundle.

---

## 7: Support layer position/scale for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21T00:00:00Z

Add CLI flags for layer positioning (scale and translation) in .icon bundles. Types exist in IconComposerFormat (IconPosition).

---

## 8: Support blend modes for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21T00:00:00Z

Add CLI support for layer blend modes in .icon bundles. All blend modes are defined in IconBlendMode enum.

---

## 9: Add visionOS .solidimagestack icon support
status: new
priority: medium
kind: feature
created: 2026-04-09T18:29:42Z

visionOS app icons use a `.solidimagestack` format with three layers (Front, Middle, Back), each containing a 1024×1024 @2x image with idiom `vision`. This is distinct from the flat `.appiconset` format used by iOS/macOS/watchOS.

Directory structure:
```
AppIcon.solidimagestack/
├── Contents.json                        # layers: [Front, Middle, Back]
├── Front.solidimagestacklayer/
│   ├── Contents.json
│   └── Content.imageset/
│       ├── Contents.json                # idiom: vision, scale: 2x
│       └── front.png
├── Middle.solidimagestacklayer/
│   ├── Contents.json
│   └── Content.imageset/
│       ├── Contents.json
│       └── middle.png
└── Back.solidimagestacklayer/
    ├── Contents.json
    └── Content.imageset/
        ├── Contents.json
        └── back.png
```

Proposed default layer mapping:
- **Back**: Background (gradient/color fill)
- **Middle**: Labels/ribbons
- **Front**: Center content

Needs:
- New output format detection for `.solidimagestack` extension
- Layer-aware rendering (render each layer separately)
- Correct Contents.json generation for each level of the hierarchy
- Add `visionos` to `AppIconPlatform` or handle as a separate output type

---

## 10: solidimagestack back layer has transparent pixels
status: new
priority: medium
kind: bug
created: 2026-04-09T19:13:28Z

When generating a .solidimagestack, the back layer PNG has alpha channel even when using a solid background color. visionOS requires the back layer to be fully opaque. Workaround: magick back.png -alpha off back.png

---

