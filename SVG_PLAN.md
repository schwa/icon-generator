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

## Decision: Approach B (IconRenderer Protocol)

We're going with **Approach B** - a high-level protocol that abstracts icon rendering, not drawing primitives.

### Rationale:

1. **Matches our domain.** We're rendering icons, not arbitrary graphics. "Render a corner ribbon" is a better abstraction than "fill a path, draw text, rotate."

2. **Handles backend differences cleanly.** SF Symbols work natively in Canvas but need rasterization for SVG. Each renderer handles this internally - no leaky abstraction.

3. **Extensible.** Adding PDF output later? Just implement `PDFIconRenderer`. Adding a new label type? Add one method to the protocol.

4. **Shared orchestration logic.** The "what to render" logic is written once. Each renderer only implements "how to render."

5. **Testable.** Easy to create a mock renderer for testing rendering logic.

---

## Implementation Plan (Approach B: IconRenderer Protocol)

### Phase 1: Protocol & Types

#### Task 1: Define IconRenderer Protocol
- [ ] Create `Sources/icon-generator/Rendering/IconRenderer.swift`
- [ ] Define the protocol:
  ```swift
  protocol IconRenderer {
      var size: CGSize { get }
      
      // Setup
      mutating func beginIcon()
      mutating func endIcon()
      
      // Background & clipping
      mutating func renderBackground(_ background: Background, cornerStyle: CornerStyle, cornerRadius: CGFloat)
      mutating func pushClip(cornerStyle: CornerStyle, cornerRadius: CGFloat)
      mutating func popClip()
      
      // Labels
      mutating func renderEdgeRibbon(position: LabelPosition, content: LabelContent, backgroundColor: Color, foregroundColor: Color, rotation: Double)
      mutating func renderCornerRibbon(position: LabelPosition, content: LabelContent, backgroundColor: Color, foregroundColor: Color, rotateContent: Bool, rotation: Double)
      mutating func renderPill(position: LabelPosition, content: LabelContent, backgroundColor: Color, foregroundColor: Color, rotation: Double)
      
      // Center content
      mutating func renderCenterContent(_ content: CenterContent)
  }
  ```
- [ ] Consider: Should we pass `IconLabel` directly or decompose into parameters?

#### Task 2: Define Supporting Types
- [ ] Create `Sources/icon-generator/Rendering/Fill.swift`
  ```swift
  enum Fill {
      case color(Color)
      case linearGradient(stops: [GradientStop], from: UnitPoint, to: UnitPoint)
      case radialGradient(stops: [GradientStop], center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat)
      case angularGradient(stops: [GradientStop], center: UnitPoint)
  }
  
  struct GradientStop {
      let color: Color
      let location: CGFloat
  }
  ```
- [ ] Or reuse existing `Background` type if sufficient

#### Task 3: Create Render Orchestration
- [ ] Create `Sources/icon-generator/Rendering/IconRenderPipeline.swift`
  ```swift
  func renderIcon<R: IconRenderer>(
      to renderer: inout R,
      background: Background,
      cornerStyle: CornerStyle,
      cornerRadius: CGFloat,
      labels: [IconLabel],
      centerContent: CenterContent?
  ) {
      renderer.beginIcon()
      renderer.renderBackground(background, cornerStyle: cornerStyle, cornerRadius: cornerRadius)
      
      // Center content drawn before clipping
      if let center = centerContent {
          renderer.renderCenterContent(center)
      }
      
      // Clip for labels
      renderer.pushClip(cornerStyle: cornerStyle, cornerRadius: cornerRadius)
      
      for label in labels {
          switch label.position {
          case .top, .bottom, .left, .right:
              renderer.renderEdgeRibbon(...)
          case .topLeft, .topRight, .bottomLeft, .bottomRight:
              renderer.renderCornerRibbon(...)
          case .pillLeft, .pillCenter, .pillRight:
              renderer.renderPill(...)
          }
      }
      
      renderer.popClip()
      renderer.endIcon()
  }
  ```

### Phase 2: Canvas/PNG Renderer

#### Task 4: Create CanvasIconRenderer
- [ ] Create `Sources/icon-generator/Rendering/CanvasIconRenderer.swift`
- [ ] Wrap `GraphicsContext` and implement `IconRenderer`
- [ ] Implement `renderBackground`:
  - Convert `Background` → `GraphicsContext.Shading`
  - Fill squircle path
- [ ] Implement `pushClip`/`popClip`:
  - Use `context.clip(to:)`
  - Note: GraphicsContext clip is "permanent" - may need transform approach or separate context
- [ ] Implement `renderEdgeRibbon`:
  - Compute ribbon rect
  - Fill background
  - Resolve and draw content (text/symbol/image)
  - Handle rotation for left/right ribbons
- [ ] Implement `renderCornerRibbon`:
  - Compute triangle path
  - Fill background  
  - Position content at centroid
  - Apply rotation transform
- [ ] Implement `renderPill`:
  - Compute pill rect based on content size
  - Fill rounded rect
  - Draw centered content
- [ ] Implement `renderCenterContent`:
  - Use `context.resolve(Text(...))` or `context.resolve(Image(...))`
  - Apply size, color, rotation, offset

#### Task 5: Integrate into SquircleView
- [ ] Update `SquircleView` to use `CanvasIconRenderer` + `renderIcon()`
- [ ] Remove `symbols:` closure (use inline resolution instead)
- [ ] Remove `drawLabel` method (now in renderer)
- [ ] Verify PNG output matches current behavior
- [ ] Run all existing tests - must pass!

### Phase 3: SVG Infrastructure

#### Task 6: SVG Utilities
- [ ] Create `Sources/icon-generator/Rendering/SVG/SVGUtilities.swift`
- [ ] `Path` → SVG `d` attribute:
  ```swift
  extension Path {
      func svgPathData() -> String {
          var d = ""
          forEach { element in
              switch element {
              case .move(let to): d += "M \(to.x) \(to.y) "
              case .line(let to): d += "L \(to.x) \(to.y) "
              case .quadCurve(let to, let control): d += "Q \(control.x) \(control.y) \(to.x) \(to.y) "
              case .curve(let to, let c1, let c2): d += "C \(c1.x) \(c1.y) \(c2.x) \(c2.y) \(to.x) \(to.y) "
              case .closeSubpath: d += "Z "
              }
          }
          return d
      }
  }
  ```
- [ ] `Color` → SVG color string
- [ ] XML escaping for text content

#### Task 7: SVG Document Builder
- [ ] Create `Sources/icon-generator/Rendering/SVG/SVGDocument.swift`
- [ ] Model SVG structure:
  ```swift
  class SVGDocument {
      let width: CGFloat
      let height: CGFloat
      private var defs: [String] = []
      private var elements: [String] = []
      
      func addDef(_ def: String) -> String  // Returns ID
      func addElement(_ element: String)
      func toString() -> String
  }
  ```
- [ ] Generate `<linearGradient>`, `<radialGradient>`
- [ ] Generate `<clipPath>`

### Phase 4: SVG Renderer

#### Task 8: Create SVGIconRenderer
- [ ] Create `Sources/icon-generator/Rendering/SVG/SVGIconRenderer.swift`
- [ ] Implement `IconRenderer` protocol
- [ ] `renderBackground`:
  - Solid color → `fill="#RRGGBB"`
  - Gradient → add to `<defs>`, use `fill="url(#gradientId)"`
- [ ] `pushClip`/`popClip`:
  - Generate `<clipPath>` in defs
  - Track current clip ID
  - Apply `clip-path="url(#clipId)"` to subsequent elements
- [ ] `renderEdgeRibbon`:
  - `<rect>` for background
  - `<text>` or `<image>` for content
  - `transform="rotate(...)"` for left/right
- [ ] `renderCornerRibbon`:
  - `<path>` for triangle
  - Content with rotation transform
- [ ] `renderPill`:
  - `<rect rx="..." ry="...">` for rounded rect
  - Centered content

#### Task 9: SVG Content Rendering
- [ ] Text rendering:
  ```svg
  <text x="512" y="512" 
        font-family="-apple-system, system-ui, sans-serif"
        font-size="80" font-weight="bold"
        text-anchor="middle" dominant-baseline="central"
        fill="#FFFFFF">BETA</text>
  ```
- [ ] SF Symbol rendering:
  - Rasterize using `ImageRenderer` + `Image(systemName:)`
  - Embed as base64: `<image href="data:image/png;base64,..." />`
- [ ] Image rendering:
  - Load image, convert to PNG data
  - Embed as base64 `<image>`

#### Task 10: SVG Output Method
- [ ] Add `func toSVG() -> String` to `SVGIconRenderer`
- [ ] Combine defs + elements into complete SVG document

### Phase 5: Integration & CLI

#### Task 11: CLI Integration
- [ ] Add output format detection:
  ```swift
  let isSVG = resolvedOutput.hasSuffix(".svg")
  ```
- [ ] Route to appropriate renderer:
  ```swift
  if isSVG {
      var renderer = SVGIconRenderer(size: CGSize(width: size, height: size))
      renderIcon(to: &renderer, ...)
      let svg = renderer.toSVG()
      try svg.write(to: url, atomically: true, encoding: .utf8)
  } else {
      // Current PNG path using CanvasIconRenderer
  }
  ```
- [ ] Update help text with SVG example

#### Task 12: Testing
- [ ] Unit tests for `Path.svgPathData()`
- [ ] Unit tests for color/gradient conversion
- [ ] Integration tests:
  - [ ] Basic icon → SVG
  - [ ] Kitchen sink → SVG
  - [ ] All label positions
  - [ ] All center content types (text, SF Symbol, image)
  - [ ] Gradients (linear, radial)
- [ ] Manual verification: open SVG in browser

### Phase 6: Polish

#### Task 13: Edge Cases
- [ ] Angular gradients: log warning, fall back to first color
- [ ] Empty/missing SF Symbols: placeholder or skip
- [ ] Special characters in text: XML escape
- [ ] Very large content: ensure viewBox is correct

#### Task 14: Documentation
- [ ] Update AGENTS.md with SVG output
- [ ] Document limitations (angular gradients, SF Symbol rasterization)
- [ ] Add CLI examples

---

## Open Questions

1. **SF Symbols in SVG:** Rasterize + embed as base64 `<image>`? This is reliable but loses vector scaling. Acceptable for now?

2. **Angular gradients:** SVG doesn't support them natively. Options:
   - Skip with warning, fall back to first color
   - Approximate with many linear gradient stops
   - Use `<foreignObject>` with CSS (poor compatibility)
   - **Recommendation:** Fall back with warning for MVP

3. **Text centering:** SVG text positioning differs from SwiftUI. May need manual baseline adjustments. Test thoroughly.

4. **Squircle accuracy:** We can iterate `Path.Element` to get the Bézier curves. Should be accurate, but verify.

5. **Protocol design:** Should `renderEdgeRibbon` etc. take `IconLabel` directly, or decomposed parameters? Taking `IconLabel` is simpler but couples protocol to our model types.

6. **Clip state in GraphicsContext:** `context.clip()` is not reversible. May need to use transform copies or restructure rendering order.

---

## Estimated Effort

| Phase | Tasks | Estimate |
|-------|-------|----------|
| Phase 1: Protocol & Types | 1-3 | 0.5 day |
| Phase 2: Canvas/PNG Renderer | 4-5 | 1 day |
| Phase 3: SVG Infrastructure | 6-7 | 0.5 day |
| Phase 4: SVG Renderer | 8-10 | 1-1.5 days |
| Phase 5: Integration & CLI | 11-12 | 0.5 day |
| Phase 6: Polish | 13-14 | 0.5 day |

**Total: 4-5 days**

---

## Success Criteria

1. **PNG unchanged:** All existing tests pass, PNG output identical to before
2. **SVG valid:** `icon-generator -o test.svg` produces well-formed SVG
3. **SVG renders:** Opens correctly in Chrome, Safari, Firefox
4. **Kitchen sink works:** `icon-generator --kitchen-sink -o demo.svg` shows all features
5. **All label types:** Edge ribbons, corner ribbons, pills all render in SVG
6. **All content types:** Text, SF Symbols, and images work in SVG
7. **Gradients:** Linear and radial gradients work in SVG
8. **Rotation:** Center content and label rotation work in SVG

---

## File Structure (Proposed)

```
Sources/icon-generator/
├── Rendering/
│   ├── IconRenderer.swift           # Protocol definition
│   ├── IconRenderPipeline.swift     # Orchestration logic
│   ├── Fill.swift                   # Fill types (if needed)
│   ├── CanvasIconRenderer.swift     # PNG/Canvas implementation
│   └── SVG/
│       ├── SVGIconRenderer.swift    # SVG implementation
│       ├── SVGDocument.swift        # SVG document builder
│       └── SVGUtilities.swift       # Path conversion, etc.
├── SquircleView.swift               # Updated to use IconRenderer
├── ... (existing files)
```
