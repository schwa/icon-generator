## 1: Add more PNG vs SVG renderer comparison tests
status: new
priority: low
kind: enhancement
created: 2026-02-21

Currently we have a single basic squircle comparison test between PNG (CanvasIconRenderer) and SVG (SVGIconRenderer via WebKit rasterization). Should add more tests covering gradients, labels, center content, etc. to catch renderer divergence.

---

## 2: Add --icon-platforms CLI flag for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21

Allow specifying target platforms (ios, macos, visionos, watchos) for .icon bundles via CLI. Currently hardcoded to watchOS circles + shared squares.

---

## 3: Add --blur-material CLI flag for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21

Add CLI support for visionOS blur material effect (0.0-1.0 strength). The type already exists in IconComposerFormat.

---

## 4: Add .icon configuration support to JSON config files
status: new
priority: low
kind: feature
labels: icon-format, config
created: 2026-02-21

Allow specifying .icon-specific options (translucency, shadow, glass, blur-material, platforms) in JSON configuration files. Currently only CLI flags are supported.

---

## 5: Support appearance specializations for .icon output
status: new
priority: low
kind: feature
labels: icon-format
created: 2026-02-21

Allow generating .icon bundles with light/dark/tinted appearance variants. Would require rendering multiple SVG assets per layer and adding specialization entries. Types already support this in IconComposerFormat.

---

## 6: Add --import-icon flag to read existing .icon bundles
status: new
priority: low
kind: feature
labels: icon-format
created: 2026-02-21

Allow importing an existing .icon bundle and dumping its configuration, or using it as a base for modifications. Would require adding read support back to IconBundle.

---

## 7: Support layer position/scale for .icon output
status: new
priority: low
kind: feature
labels: icon-format, cli
created: 2026-02-21

Add CLI flags for layer positioning (scale and translation) in .icon bundles. Types exist in IconComposerFormat (IconPosition).

---

## 8: Support blend modes for .icon output
status: new
priority: low
kind: feature
labels: icon-format,cli
created: 2026-02-21

Add CLI support for layer blend modes in .icon bundles. All blend modes are defined in IconBlendMode enum.

---

