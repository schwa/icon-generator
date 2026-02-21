import SwiftUI

// MARK: - Path to SVG Conversion

extension Path {
    /// Convert a SwiftUI Path to an SVG path data string
    public func svgPathData() -> String {
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
    public func svgString() -> String {
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
            return "rgba(\(r),\(g),\(b),\(SVGFormatting.formatNumber(CGFloat(a))))"
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

// MARK: - Transform Helpers

public enum SVGTransform {
    /// Create a translate transform string
    public static func translate(x: CGFloat, y: CGFloat) -> String {
        "translate(\(SVGFormatting.formatNumber(x)),\(SVGFormatting.formatNumber(y)))"
    }

    /// Create a rotate transform string (angle in degrees)
    public static func rotate(_ angle: CGFloat) -> String {
        "rotate(\(SVGFormatting.formatNumber(angle)))"
    }

    /// Create a rotate transform string around a point
    public static func rotate(_ angle: CGFloat, around point: CGPoint) -> String {
        "rotate(\(SVGFormatting.formatNumber(angle)),\(SVGFormatting.formatNumber(point.x)),\(SVGFormatting.formatNumber(point.y)))"
    }

    /// Create a scale transform string
    public static func scale(x: CGFloat, y: CGFloat) -> String {
        if x == y {
            return "scale(\(SVGFormatting.formatNumber(x)))"
        }
        return "scale(\(SVGFormatting.formatNumber(x)),\(SVGFormatting.formatNumber(y)))"
    }

    /// Combine multiple transforms
    public static func combine(_ transforms: [String]) -> String {
        transforms.joined(separator: " ")
    }
}

// MARK: - Formatting Helpers

public enum SVGFormatting {
    /// Format a point for SVG path data
    public static func formatPoint(_ point: CGPoint) -> String {
        "\(formatNumber(point.x)),\(formatNumber(point.y))"
    }

    /// Format a CGFloat for SVG output
    public static func formatNumber(_ value: CGFloat) -> String {
        if value == value.rounded() {
            return String(Int(value))
        } else {
            let rounded = (value * 10000).rounded() / 10000
            return String(format: "%g", rounded)
        }
    }
}

// Private helper for Path extension
private func formatPoint(_ point: CGPoint) -> String {
    SVGFormatting.formatPoint(point)
}
