import SwiftUI

// MARK: - Path to SVG Conversion

extension Path {
    /// Convert a SwiftUI Path to an SVG path data string
    func svgPathData() -> String {
        var d = ""

        forEach { element in
            switch element {
            case .move(let to):
                d += "M\(formatPoint(to))"
            case .line(let to):
                d += "L\(formatPoint(to))"
            case .quadCurve(let to, let control):
                d += "Q\(formatPoint(control)) \(formatPoint(to))"
            case .curve(let to, let control1, let control2):
                d += "C\(formatPoint(control1)) \(formatPoint(control2)) \(formatPoint(to))"
            case .closeSubpath:
                d += "Z"
            }
        }

        return d
    }
}

// MARK: - Color Conversion

extension Color {
    /// Convert to SVG color string
    /// Returns hex format #RRGGBB or rgba() for colors with alpha
    func svgString() -> String {
        // Get the resolved color components
        let cgColor = NSColor(self).cgColor
        guard let components = cgColor.components,
              components.count >= 3 else {
            return "#000000"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        let a = components.count >= 4 ? components[3] : 1.0

        if a < 1.0 {
            return "rgba(\(r),\(g),\(b),\(formatNumber(CGFloat(a))))"
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

extension CSSColor {
    /// Convert to SVG color string
    func svgString() -> String {
        if let color = self.color() {
            return color.svgString()
        }
        // Fallback to the raw value (might already be a valid CSS color)
        return rawValue
    }
}

// MARK: - Transform Helpers

enum SVGTransform {
    /// Create a translate transform string
    static func translate(x: CGFloat, y: CGFloat) -> String {
        "translate(\(formatNumber(x)),\(formatNumber(y)))"
    }

    /// Create a rotate transform string (angle in degrees)
    static func rotate(_ angle: CGFloat) -> String {
        "rotate(\(formatNumber(angle)))"
    }

    /// Create a rotate transform string around a point
    static func rotate(_ angle: CGFloat, around point: CGPoint) -> String {
        "rotate(\(formatNumber(angle)),\(formatNumber(point.x)),\(formatNumber(point.y)))"
    }

    /// Create a scale transform string
    static func scale(x: CGFloat, y: CGFloat) -> String {
        if x == y {
            return "scale(\(formatNumber(x)))"
        }
        return "scale(\(formatNumber(x)),\(formatNumber(y)))"
    }

    /// Combine multiple transforms
    static func combine(_ transforms: [String]) -> String {
        transforms.joined(separator: " ")
    }
}

// MARK: - Gradient Conversion

extension Background {
    /// Generate SVG gradient element if this is a gradient background
    /// Returns (gradient element, fill reference) or nil for solid colors
    func svgGradient(id: String, in rect: CGRect) -> (element: XMLElement, fillRef: String)? {
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
    func svgFill(gradientID: String? = nil) -> String {
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

// MARK: - Private Helpers

/// Format a point for SVG path data
private func formatPoint(_ point: CGPoint) -> String {
    "\(formatNumber(point.x)),\(formatNumber(point.y))"
}

/// Format a CGFloat for SVG output
private func formatNumber(_ value: CGFloat) -> String {
    if value == value.rounded() {
        return String(Int(value))
    } else {
        let rounded = (value * 10000).rounded() / 10000
        return String(format: "%g", rounded)
    }
}
