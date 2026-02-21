# SVG Export Feature Plan

## Goal

Add SVG export capability to icon-generator, allowing the same icon configurations to output as either PNG or SVG.

## Current Architecture

The current `SquircleView` uses a **hybrid approach**:

```
┌─────────────────────────────────────────────────────────────┐
│                     SquircleView                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Canvas { } symbols: { }                  │
├─────────────────────────────────────────────────────────────┤
│  Canvas closure (GraphicsContext):                          │
│    - context.fill(path, with:) → background, label shapes  │
│    - context.clip(to:) → squircle clipping                 │
│    - context.translateBy/rotate → label positioning        │
│    - context.resolveSymbol(id:) → get pre-rendered views   │
│    - context.draw(symbol, at:) → draw resolved symbols     │
├─────────────────────────────────────────────────────────────┤
│  symbols: closure (SwiftUI Views):                          │
│    - centerContentView() → Text, Image(systemName:),       │
│                            Image(nsImage:)                  │
│    - labelContentView()  → Text, Image(systemName:),       │
│                            Image(nsImage:)                  │
│    (These get pre-rendered and resolved via resolveSymbol) │
└─────────────────────────────────────────────────────────────┘
```

**Key insight:** Text, SF Symbols, and embedded images are SwiftUI views that get pre-rendered by Canvas's `symbols:` mechanism. The `GraphicsContext` then draws these as opaque "resolved symbols."

**Note:** `GraphicsContext` also has `resolve(_:)` methods that can resolve `Text` and `Image` directly without the `symbols:` closure - this could simplify things.

---

## Approach Comparison

### Approach A: DrawingContext Protocol

**Idea:** Create a protocol that abstracts drawing primitives. Both `GraphicsContext` (via extension) and `SVGContext` conform to it.

```swift
protocol DrawingContext {
    mutating func fillPath(_ path: Path, with fill: Fill)
    mutating func clip(to path: Path)
    mutating func pushTransform(_ transform: CGAffineTransform)
    mutating func popTransform()
    mutating func drawText(_ text: String, at: CGPoint, style: TextStyle)
    mutating func drawSymbol(_ name: String, at: CGPoint, style: SymbolStyle)
    mutating func drawImage(_ image: CGImage, in: CGRect)
}

extension GraphicsContext: DrawingContext {
    // Map our API to GraphicsContext's native API
}

class SVGContext: DrawingContext {
    // Record drawing commands as SVG elements
}

// Shared rendering logic:
func renderIcon(to context: inout some DrawingContext, config: IconConfig) {
    context.fillPath(backgroundPath, with: config.background)
    context.clip(to: squirclePath)
    // ... etc
}
```

**Pros:**
- Clean abstraction at the drawing primitive level
- Rendering logic written once, works for both outputs
- Easy to add more backends (PDF, etc.)
- Testable with mock context

**Cons:**
- Must design protocol carefully to cover all our needs
- `GraphicsContext` conformance may be awkward (it's a struct with mutating methods, associated types)
- Lower-level abstraction means more protocol surface area
- Still need to handle SF Symbols differently per backend

---

### Approach B: IconRenderer Protocol

**Idea:** Abstract at the icon level, not the drawing level. Each renderer knows how to render icon components to its target.

```swift
protocol IconRenderer {
    mutating func renderBackground(_ bg: Background, rect: CGRect, cornerStyle: CornerStyle, cornerRadius: CGFloat)
    mutating func renderEdgeRibbon(_ label: IconLabel, in rect: CGRect)
    mutating func renderCornerRibbon(_ label: IconLabel, in rect: CGRect)
    mutating func renderPill(_ label: IconLabel, in rect: CGRect)
    mutating func renderCenterContent(_ content: CenterContent, in rect: CGRect)
}

struct CanvasIconRenderer: IconRenderer {
    var context: GraphicsContext
    // Implement each method using GraphicsContext directly
}

struct SVGIconRenderer: IconRenderer {
    var elements: [SVGElement] = []
    // Implement each method by appending SVG elements
}

// Usage:
func renderIcon<R: IconRenderer>(with renderer: inout R, config: IconConfig) {
    renderer.renderBackground(config.background, ...)
    for label in config.labels {
        switch label.position {
        case .top, .bottom, .left, .right:
            renderer.renderEdgeRibbon(label, in: rect)
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            renderer.renderCornerRibbon(label, in: rect)
        case .pillLeft, .pillCenter, .pillRight:
            renderer.renderPill(label, in: rect)
        }
    }
    if let center = config.centerContent {
        renderer.renderCenterContent(center, in: rect)
    }
}
```

**Pros:**
- Higher-level abstraction matches our domain (icons, not graphics)
- Each renderer handles its own complexity internally
- SF Symbols: Canvas renderer uses native resolution, SVG renderer can rasterize - no leaky abstraction
- Easier to reason about: "render a ribbon" vs "fill a path, draw text, rotate"

**Cons:**
- Some rendering logic duplicated between renderers
- If we add new label types, must update protocol + all renderers
- Less reusable for non-icon drawing

---

### Approach C: Hybrid (Layered Protocols)

**Idea:** Two protocol layers - high-level `IconRenderer` for icon concepts, low-level `DrawingContext` for shared primitives.

```swift
// Low-level primitives
protocol DrawingContext {
    mutating func fillPath(_ path: Path, with fill: Fill)
    mutating func drawText(_ text: String, at: CGPoint, style: TextStyle)
    // ... etc
}

// High-level icon rendering with default implementations
protocol IconRenderer {
    associatedtype Context: DrawingContext
    var context: Context { get set }
    
    mutating func renderBackground(_ bg: Background, ...)
    mutating func renderEdgeRibbon(_ label: IconLabel, ...)
    // ... etc
}

// Default implementations in protocol extension
extension IconRenderer {
    mutating func renderEdgeRibbon(_ label: IconLabel, in rect: CGRect) {
        let ribbonPath = computeRibbonPath(for: label, in: rect)
        context.fillPath(ribbonPath, with: label.backgroundColor)
        context.drawText(label.text, at: ribbonCenter, style: ...)
    }
}

// Concrete renderers just provide the context
struct CanvasIconRenderer: IconRenderer {
    var context: GraphicsContext  // conforms to DrawingContext via extension
}

struct SVGIconRenderer: IconRenderer {
    var context: SVGContext  // conforms to DrawingContext
}
```

**Pros:**
- Shared rendering logic via protocol extensions
- Each backend only implements low-level primitives
- Best of both worlds?

**Cons:**
- Most complex option
- Associated types complicate usage
- May be overengineered for our needs
- Still have the DrawingContext conformance challenge

---

### Approach D: Parallel Implementations (No Shared Protocol)

**Idea:** Just write two separate renderers. Extract shared utilities but don't force a common protocol.

```swift
// PNG rendering (current approach, cleaned up)
struct PNGIconRenderer {
    func render(config: IconConfig) -> CGImage {
        // Use Canvas + GraphicsContext directly
    }
}

// SVG rendering
struct SVGIconRenderer {
    func render(config: IconConfig) -> String {
        // Build SVG document directly
    }
}

// Shared utilities (not a protocol)
enum IconGeometry {
    static func squirclePath(in rect: CGRect, cornerRadius: CGFloat, style: CornerStyle) -> Path
    static func ribbonPath(for position: LabelPosition, in rect: CGRect) -> Path
    static func pillRect(for position: LabelPosition, in rect: CGRect, contentSize: CGSize) -> CGRect
    // ... etc
}

enum SVGHelpers {
    static func pathToSVG(_ path: Path) -> String
    static func colorToSVG(_ color: Color) -> String
    // ... etc
}
```

**Pros:**
- Simplest to implement - no protocol design needed
- Each renderer is self-contained and optimized for its output
- No awkward conformances or associated types
- Easy to understand and maintain
- Can share utilities without forcing abstraction

**Cons:**
- Some logic duplication (computing positions, paths, etc.)
- Changes to icon structure must be made in two places
- Doesn't scale well if we add many output formats

---

## Recommendation

**Start with Approach D (Parallel Implementations), evolve to Approach B if needed.**

### Rationale:

1. **Simplest path to working SVG output.** We can ship SVG support faster without designing the perfect abstraction upfront.

2. **We only have two backends.** PNG and SVG. The overhead of a protocol isn't justified until we have 3+ backends.

3. **The backends are fundamentally different:**
   - PNG: Raster, uses SwiftUI's rendering pipeline, SF Symbols "just work"
   - SVG: Vector, text-based, SF Symbols need special handling (rasterize or path extraction)
   
   Forcing them into a shared protocol may create a leaky abstraction.

4. **Shared utilities are enough.** Path computation, geometry calculations, color conversion - these can be shared functions without a protocol.

5. **Easy to refactor later.** If we add PDF/HTML Canvas/etc., we can extract a protocol then with real knowledge of what needs to be shared.

### If we find significant duplication:

Evolve to **Approach B (IconRenderer Protocol)** - the high-level abstraction makes more sense than low-level drawing primitives because:
- Our domain is icons, not generic graphics
- SF Symbol handling will always differ between vector/raster outputs
- "Render a corner ribbon" is a better abstraction than "fill path, draw text, rotate"

---

## Implementation Plan (Approach D)

### Phase 1: Infrastructure

#### Task 1: SVG Utilities
- [ ] Create `SVGDocument.swift` - builds SVG string
- [ ] `Path` → SVG `d` attribute conversion (iterate `Path.Element`)
- [ ] `Color` → SVG color string (`#RRGGBB` or `rgba()`)
- [ ] Gradient → `<linearGradient>`, `<radialGradient>` definitions
- [ ] Clip path generation

#### Task 2: Shared Geometry (Extract from SquircleView)
- [ ] Create `IconGeometry.swift`
- [ ] `squirclePath(in:cornerRadius:style:)` → `Path`
- [ ] `edgeRibbonRect(for:in:)` → `CGRect`
- [ ] `cornerRibbonPath(for:in:)` → `Path` (triangle)
- [ ] `pillRect(for:in:contentSize:)` → `CGRect`
- [ ] Label text positioning calculations

### Phase 2: SVG Renderer

#### Task 3: SVGIconRenderer Core
- [ ] Create `SVGIconRenderer.swift`
- [ ] `render(config:size:) -> String`
- [ ] Render background (solid color and gradients)
- [ ] Render squircle clip path
- [ ] Structure: `<svg>` → `<defs>` → `<g clip-path>` → elements

#### Task 4: SVG Labels
- [ ] Edge ribbons (top, bottom, left, right)
- [ ] Corner ribbons (diagonal triangles with rotated content)
- [ ] Pills (rounded rect with centered content)
- [ ] Handle `rotateContent` flag

#### Task 5: SVG Content
- [ ] Text → `<text>` element with styling
- [ ] SF Symbols → rasterize to PNG, embed as base64 `<image>` (most reliable)
- [ ] Images → base64 `<image>` element
- [ ] Handle rotation transforms

### Phase 3: Integration

#### Task 6: Refactor SquircleView (Optional)
- [ ] Extract geometry calculations to `IconGeometry`
- [ ] Keep Canvas rendering logic in place
- [ ] Verify no visual regression

#### Task 7: CLI Integration
- [ ] Add `--format png|svg` option
- [ ] Auto-detect from `.svg` extension
- [ ] Wire up `SVGIconRenderer` for SVG output

#### Task 8: Testing
- [ ] Unit tests for SVG path conversion
- [ ] Unit tests for SVG gradient generation
- [ ] Integration test: generate kitchen-sink SVG
- [ ] Verify SVG renders correctly in browser
- [ ] Test all label positions
- [ ] Test all center content types

### Phase 4: Polish

#### Task 9: Handle Edge Cases
- [ ] Angular gradients (approximate or skip with warning)
- [ ] Very small sizes
- [ ] Special characters in text
- [ ] Missing SF Symbols

#### Task 10: Documentation
- [ ] Update AGENTS.md
- [ ] Document SVG-specific limitations
- [ ] Add examples

---

## Open Questions

1. **SF Symbols in SVG:** Rasterize + embed as base64 `<image>`? This is reliable but loses vector scaling. Acceptable for now?

2. **Angular gradients:** SVG doesn't support them natively. Options:
   - Skip with warning
   - Approximate with many linear gradient stops
   - Use `<foreignObject>` with CSS (poor compatibility)

3. **Text centering:** SVG text positioning differs from SwiftUI. May need manual baseline adjustments. Test thoroughly.

4. **Squircle accuracy:** We can iterate `Path.Element` to get the Bézier curves. Should be accurate, but verify.

---

## Estimated Effort

- **Phase 1 (Infrastructure):** 0.5 day
- **Phase 2 (SVG Renderer):** 1-2 days
- **Phase 3 (Integration):** 0.5 day
- **Phase 4 (Polish):** 0.5-1 day

**Total: 2.5-4 days**

## Success Criteria

1. `icon-generator --kitchen-sink -o demo.svg` produces valid SVG
2. SVG renders correctly in modern browsers (Chrome, Safari, Firefox)
3. All label types work in SVG output
4. Gradients (linear, radial) work in SVG output
5. Center content (text, SF Symbols, images) works in SVG output
6. Existing PNG output is unaffected
