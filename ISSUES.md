## 1: Add more PNG vs SVG renderer comparison tests
status: new
priority: low
kind: enhancement
created: 2026-02-21

Currently we have a single basic squircle comparison test between PNG (CanvasIconRenderer) and SVG (SVGIconRenderer via WebKit rasterization). Should add more tests covering gradients, labels, center content, etc. to catch renderer divergence.

---

