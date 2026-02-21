import SwiftUI

/// A builder for constructing SVG documents using XMLElement
class SVGDocument {
    let width: CGFloat
    let height: CGFloat

    private var defs: [XMLElement] = []
    private var bodyElements: [XMLElement] = []
    private var idCounter = 0

    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    // MARK: - ID Generation

    /// Generate a unique ID for definitions
    func generateID(prefix: String = "id") -> String {
        idCounter += 1
        return "\(prefix)\(idCounter)"
    }

    // MARK: - Definitions

    /// Add a definition element (gradient, clipPath, etc.) and return its ID
    @discardableResult
    func addDef(_ element: XMLElement) -> String {
        // Extract or generate ID
        let id = element.attributes["id"] ?? generateID()
        var elementWithID = element
        elementWithID.attributes["id"] = id
        defs.append(elementWithID)
        return id
    }

    /// Add a gradient definition from a Background
    /// Returns the fill reference (e.g., "url(#grad1)") or nil if solid color
    func addGradient(from background: Background, id: String? = nil) -> String? {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let gradientID = id ?? generateID(prefix: "gradient")

        if let (element, fillRef) = background.svgGradient(id: gradientID, in: rect) {
            defs.append(element)
            return fillRef
        }
        return nil
    }

    /// Add a clip path definition
    func addClipPath(path: Path, id: String? = nil) -> String {
        let clipID = id ?? generateID(prefix: "clip")
        let pathData = path.svgPathData()
        let clipPath = XMLElement.clipPath(id: clipID, children: [
            XMLElement.path(d: pathData, fill: nil),
        ])
        defs.append(clipPath)
        return clipID
    }

    // MARK: - Body Elements

    /// Add an element to the document body
    func addElement(_ element: XMLElement) {
        bodyElements.append(element)
    }

    /// Add multiple elements to the document body
    func addElements(_ elements: [XMLElement]) {
        bodyElements.append(contentsOf: elements)
    }

    /// Add a group of elements
    func addGroup(transform: String? = nil, clipPath: String? = nil, children: [XMLElement]) {
        let group = XMLElement.g(transform: transform, clipPath: clipPath, children: children)
        bodyElements.append(group)
    }

    // MARK: - Building

    /// Build the complete SVG document as XMLElement
    func build() -> XMLElement {
        var children: [XMLElement] = []

        // Add defs if any
        if !defs.isEmpty {
            children.append(XMLElement.defs(children: defs))
        }

        // Add body elements
        children.append(contentsOf: bodyElements)

        return XMLElement.svg(width: width, height: height, children: children)
    }

    /// Render the document to an SVG string
    func render(compact: Bool = false) -> String {
        let svg = build()
        let xmlDeclaration = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"

        if compact {
            return xmlDeclaration + svg.renderCompact()
        } else {
            return xmlDeclaration + svg.render()
        }
    }
}

// MARK: - Convenience Methods

extension SVGDocument {
    /// Add a filled rectangle
    func addRect(
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat,
        height: CGFloat,
        rx: CGFloat? = nil,
        fill: String
    ) {
        addElement(XMLElement.rect(x: x, y: y, width: width, height: height, rx: rx, ry: rx, fill: fill))
    }

    /// Add a filled path
    func addPath(d: String, fill: String) {
        addElement(XMLElement.path(d: d, fill: fill))
    }

    /// Add text
    func addText(
        _ content: String,
        x: CGFloat,
        y: CGFloat,
        fontSize: CGFloat,
        fontWeight: String = "bold",
        fill: String,
        textAnchor: String = "middle",
        dominantBaseline: String = "central",
        transform: String? = nil
    ) {
        addElement(XMLElement.text(
            content,
            x: x,
            y: y,
            fontSize: fontSize,
            fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif",
            fontWeight: fontWeight,
            fill: fill,
            textAnchor: textAnchor,
            dominantBaseline: dominantBaseline,
            transform: transform
        ))
    }

    /// Add an embedded image (base64)
    func addImage(
        data: Data,
        mimeType: String = "image/png",
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        transform: String? = nil
    ) {
        let base64 = data.base64EncodedString()
        let href = "data:\(mimeType);base64,\(base64)"
        addElement(XMLElement.image(href: href, x: x, y: y, width: width, height: height, transform: transform))
    }
}
