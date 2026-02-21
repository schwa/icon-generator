import Foundation

// MARK: - XML Element

/// A type-safe representation of an XML element
public struct XMLElement {
    public var name: String
    public var attributes: [String: String] = [:]
    public var children: [XMLContent] = []

    public init(name: String, attributes: [String: String] = [:], children: [XMLContent] = []) {
        self.name = name
        self.attributes = attributes
        self.children = children
    }

    /// Convenience initializer for elements with only element children
    public init(name: String, attributes: [String: String] = [:], children: [XMLElement]) {
        self.name = name
        self.attributes = attributes
        self.children = children.map { .element($0) }
    }

    /// Convenience initializer for elements with text content
    public init(name: String, attributes: [String: String] = [:], text: String) {
        self.name = name
        self.attributes = attributes
        self.children = [.text(text)]
    }
}

// MARK: - XML Content

/// Content that can appear inside an XML element
public enum XMLContent {
    case element(XMLElement)
    case text(String)
    case cdata(String)
    case comment(String)
}

// MARK: - Rendering

extension XMLElement {
    /// Render to XML string with optional indentation
    public func render(indent: Int = 0, indentString: String = "  ") -> String {
        let prefix = String(repeating: indentString, count: indent)
        var result = prefix + "<" + name

        // Sort attributes for consistent output
        let sortedAttributes = attributes.sorted { $0.key < $1.key }
        for (key, value) in sortedAttributes {
            result += " \(key)=\"\(escapeAttribute(value))\""
        }

        if children.isEmpty {
            result += "/>"
        } else {
            result += ">"

            // Check if we have only text content (inline it)
            if children.count == 1, case .text(let text) = children[0] {
                result += escapeText(text)
                result += "</\(name)>"
            } else {
                result += "\n"
                for child in children {
                    result += child.render(indent: indent + 1, indentString: indentString)
                }
                result += prefix + "</\(name)>"
            }
        }

        return result + "\n"
    }

    /// Render to compact XML string (no indentation)
    public func renderCompact() -> String {
        var result = "<" + name

        for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
            result += " \(key)=\"\(escapeAttribute(value))\""
        }

        if children.isEmpty {
            result += "/>"
        } else {
            result += ">"
            for child in children {
                result += child.renderCompact()
            }
            result += "</\(name)>"
        }

        return result
    }
}

extension XMLContent {
    public func render(indent: Int = 0, indentString: String = "  ") -> String {
        let prefix = String(repeating: indentString, count: indent)

        switch self {
        case .element(let element):
            return element.render(indent: indent, indentString: indentString)
        case .text(let text):
            return prefix + escapeText(text) + "\n"
        case .cdata(let content):
            return prefix + "<![CDATA[\(content)]]>\n"
        case .comment(let comment):
            return prefix + "<!-- \(comment) -->\n"
        }
    }

    public func renderCompact() -> String {
        switch self {
        case .element(let element):
            return element.renderCompact()
        case .text(let text):
            return escapeText(text)
        case .cdata(let content):
            return "<![CDATA[\(content)]]>"
        case .comment(let comment):
            return "<!--\(comment)-->"
        }
    }
}

// MARK: - XML Escaping

/// Escape special characters in XML text content
private func escapeText(_ text: String) -> String {
    var result = text
    result = result.replacingOccurrences(of: "&", with: "&amp;")
    result = result.replacingOccurrences(of: "<", with: "&lt;")
    result = result.replacingOccurrences(of: ">", with: "&gt;")
    return result
}

/// Escape special characters in XML attribute values
private func escapeAttribute(_ value: String) -> String {
    var result = value
    result = result.replacingOccurrences(of: "&", with: "&amp;")
    result = result.replacingOccurrences(of: "<", with: "&lt;")
    result = result.replacingOccurrences(of: ">", with: "&gt;")
    result = result.replacingOccurrences(of: "\"", with: "&quot;")
    result = result.replacingOccurrences(of: "'", with: "&apos;")
    return result
}

// MARK: - SVG Element Helpers

extension XMLElement {
    /// Create an SVG root element
    public static func svg(
        width: CGFloat,
        height: CGFloat,
        viewBox: String? = nil,
        children: [XMLElement] = []
    ) -> XMLElement {
        var attrs: [String: String] = [
            "xmlns": "http://www.w3.org/2000/svg",
            "width": formatNumber(width),
            "height": formatNumber(height),
        ]
        if let viewBox = viewBox {
            attrs["viewBox"] = viewBox
        } else {
            attrs["viewBox"] = "0 0 \(formatNumber(width)) \(formatNumber(height))"
        }
        return XMLElement(name: "svg", attributes: attrs, children: children)
    }

    /// Create a defs element (for gradients, clip paths, etc.)
    public static func defs(children: [XMLElement]) -> XMLElement {
        XMLElement(name: "defs", children: children)
    }

    /// Create a group element
    public static func g(
        transform: String? = nil,
        clipPath: String? = nil,
        children: [XMLElement] = []
    ) -> XMLElement {
        var attrs: [String: String] = [:]
        if let transform = transform {
            attrs["transform"] = transform
        }
        if let clipPath = clipPath {
            attrs["clip-path"] = "url(#\(clipPath))"
        }
        return XMLElement(name: "g", attributes: attrs, children: children)
    }

    /// Create a rect element
    public static func rect(
        x: CGFloat = 0,
        y: CGFloat = 0,
        width: CGFloat,
        height: CGFloat,
        rx: CGFloat? = nil,
        ry: CGFloat? = nil,
        fill: String? = nil,
        stroke: String? = nil,
        strokeWidth: CGFloat? = nil
    ) -> XMLElement {
        var attrs: [String: String] = [
            "x": formatNumber(x),
            "y": formatNumber(y),
            "width": formatNumber(width),
            "height": formatNumber(height),
        ]
        if let rx = rx { attrs["rx"] = formatNumber(rx) }
        if let ry = ry { attrs["ry"] = formatNumber(ry) }
        if let fill = fill { attrs["fill"] = fill }
        if let stroke = stroke { attrs["stroke"] = stroke }
        if let strokeWidth = strokeWidth { attrs["stroke-width"] = formatNumber(strokeWidth) }
        return XMLElement(name: "rect", attributes: attrs)
    }

    /// Create a path element
    public static func path(
        d: String,
        fill: String? = nil,
        stroke: String? = nil,
        strokeWidth: CGFloat? = nil,
        fillRule: String? = nil
    ) -> XMLElement {
        var attrs: [String: String] = ["d": d]
        if let fill = fill { attrs["fill"] = fill }
        if let stroke = stroke { attrs["stroke"] = stroke }
        if let strokeWidth = strokeWidth { attrs["stroke-width"] = formatNumber(strokeWidth) }
        if let fillRule = fillRule { attrs["fill-rule"] = fillRule }
        return XMLElement(name: "path", attributes: attrs)
    }

    /// Create a circle element
    public static func circle(
        cx: CGFloat,
        cy: CGFloat,
        r: CGFloat,
        fill: String? = nil,
        stroke: String? = nil,
        strokeWidth: CGFloat? = nil
    ) -> XMLElement {
        var attrs: [String: String] = [
            "cx": formatNumber(cx),
            "cy": formatNumber(cy),
            "r": formatNumber(r),
        ]
        if let fill = fill { attrs["fill"] = fill }
        if let stroke = stroke { attrs["stroke"] = stroke }
        if let strokeWidth = strokeWidth { attrs["stroke-width"] = formatNumber(strokeWidth) }
        return XMLElement(name: "circle", attributes: attrs)
    }

    /// Create a text element
    public static func text(
        _ content: String,
        x: CGFloat,
        y: CGFloat,
        fontSize: CGFloat? = nil,
        fontFamily: String? = nil,
        fontWeight: String? = nil,
        fill: String? = nil,
        textAnchor: String? = nil,
        dominantBaseline: String? = nil,
        transform: String? = nil
    ) -> XMLElement {
        var attrs: [String: String] = [
            "x": formatNumber(x),
            "y": formatNumber(y),
        ]
        if let fontSize = fontSize { attrs["font-size"] = formatNumber(fontSize) }
        if let fontFamily = fontFamily { attrs["font-family"] = fontFamily }
        if let fontWeight = fontWeight { attrs["font-weight"] = fontWeight }
        if let fill = fill { attrs["fill"] = fill }
        if let textAnchor = textAnchor { attrs["text-anchor"] = textAnchor }
        if let dominantBaseline = dominantBaseline { attrs["dominant-baseline"] = dominantBaseline }
        if let transform = transform { attrs["transform"] = transform }
        return XMLElement(name: "text", attributes: attrs, text: content)
    }

    /// Create an image element (for embedded images)
    public static func image(
        href: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        transform: String? = nil
    ) -> XMLElement {
        var attrs: [String: String] = [
            "href": href,
            "x": formatNumber(x),
            "y": formatNumber(y),
            "width": formatNumber(width),
            "height": formatNumber(height),
        ]
        if let transform = transform { attrs["transform"] = transform }
        return XMLElement(name: "image", attributes: attrs)
    }

    /// Create a clipPath element
    public static func clipPath(id: String, children: [XMLElement]) -> XMLElement {
        XMLElement(name: "clipPath", attributes: ["id": id], children: children)
    }

    /// Create a linearGradient element
    public static func linearGradient(
        id: String,
        x1: String = "0%",
        y1: String = "0%",
        x2: String = "0%",
        y2: String = "100%",
        stops: [(offset: String, color: String)]
    ) -> XMLElement {
        let stopElements = stops.map { stop in
            XMLElement(name: "stop", attributes: [
                "offset": stop.offset,
                "stop-color": stop.color,
            ])
        }
        return XMLElement(
            name: "linearGradient",
            attributes: ["id": id, "x1": x1, "y1": y1, "x2": x2, "y2": y2],
            children: stopElements
        )
    }

    /// Create a radialGradient element
    public static func radialGradient(
        id: String,
        cx: String = "50%",
        cy: String = "50%",
        r: String = "50%",
        stops: [(offset: String, color: String)]
    ) -> XMLElement {
        let stopElements = stops.map { stop in
            XMLElement(name: "stop", attributes: [
                "offset": stop.offset,
                "stop-color": stop.color,
            ])
        }
        return XMLElement(
            name: "radialGradient",
            attributes: ["id": id, "cx": cx, "cy": cy, "r": r],
            children: stopElements
        )
    }
}

// MARK: - Number Formatting

/// Format a CGFloat for SVG output (clean, minimal decimal places)
private func formatNumber(_ value: CGFloat) -> String {
    if value == value.rounded() {
        return String(Int(value))
    } else {
        // Round to 4 decimal places to avoid floating point noise
        let rounded = (value * 10000).rounded() / 10000
        return String(format: "%g", rounded)
    }
}
