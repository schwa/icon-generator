import SwiftUI
import SVGXML

// MARK: - SVGDocument Gradient Extension

extension SVGDocument {
    /// Add a gradient definition from a Background
    /// Returns the fill reference (e.g., "url(#grad1)") or nil if solid color
    public func addGradient(from background: Background, id: String? = nil) -> String? {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let gradientID = id ?? generateID(prefix: "gradient")

        if let (element, fillRef) = background.svgGradient(id: gradientID, in: rect) {
            addDef(element)
            return fillRef
        }
        return nil
    }
}

// MARK: - CSSColor SVG Extension

extension CSSColor {
    /// Convert to SVG color string
    public func svgString() -> String {
        if let color = self.color() {
            return color.svgString()
        }
        // Fallback to the raw value (might already be a valid CSS color)
        return rawValue
    }
}

// MARK: - Background SVG Extensions

extension Background {
    /// Generate SVG gradient element if this is a gradient background
    /// Returns (gradient element, fill reference) or nil for solid colors
    public func svgGradient(id: String, in rect: CGRect) -> (element: SVGXML.XMLElement, fillRef: String)? {
        switch self {
        case .solid:
            return nil

        case .linearGradient(let colors, let startPoint, let endPoint):
            let stops = colors.enumerated().map { index, color -> (offset: String, color: String) in
                let offset = colors.count > 1 ? CGFloat(index) / CGFloat(colors.count - 1) : 0
                return (offset: "\(Int(offset * 100))%", color: color.svgString())
            }

            let element = XMLElement.linearGradient(
                id: id,
                x1: "\(Int(startPoint.x * 100))%",
                y1: "\(Int(startPoint.y * 100))%",
                x2: "\(Int(endPoint.x * 100))%",
                y2: "\(Int(endPoint.y * 100))%",
                stops: stops
            )
            return (element, "url(#\(id))")

        case .radialGradient(let colors, let center, _, let endRadius):
            let stops = colors.enumerated().map { index, color -> (offset: String, color: String) in
                let offset = colors.count > 1 ? CGFloat(index) / CGFloat(colors.count - 1) : 0
                return (offset: "\(Int(offset * 100))%", color: color.svgString())
            }

            // Approximate radius as percentage
            let radiusPercent = Int(endRadius * 100)

            let element = XMLElement.radialGradient(
                id: id,
                cx: "\(Int(center.x * 100))%",
                cy: "\(Int(center.y * 100))%",
                r: "\(radiusPercent)%",
                stops: stops
            )
            return (element, "url(#\(id))")

        case .angularGradient:
            // SVG doesn't support angular/conic gradients natively
            // Fall back to first color (handled by svgFill)
            // TODO: Could approximate with multiple gradient stops
            return nil
        }
    }

    /// Get SVG fill value (color string or gradient reference)
    public func svgFill(gradientID: String? = nil) -> String {
        switch self {
        case .solid(let color):
            return color.svgString()
        case .linearGradient, .radialGradient:
            if let id = gradientID {
                return "url(#\(id))"
            }
            // Fallback to first color
            return firstColorString()
        case .angularGradient:
            // Not supported, use first color
            return firstColorString()
        }
    }

    private func firstColorString() -> String {
        switch self {
        case .solid(let color):
            return color.svgString()
        case .linearGradient(let colors, _, _),
             .radialGradient(let colors, _, _, _),
             .angularGradient(let colors, _, _):
            return colors.first?.svgString() ?? "#000000"
        }
    }
}
