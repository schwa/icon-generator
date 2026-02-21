import SwiftUI

/// Represents a background fill - either a solid color or a gradient
public enum Background: Sendable, Equatable {
    case solid(CSSColor)
    case linearGradient(colors: [CSSColor], startPoint: UnitPoint, endPoint: UnitPoint)
    case radialGradient(colors: [CSSColor], center: UnitPoint, startRadius: CGFloat, endRadius: CGFloat)
    case angularGradient(colors: [CSSColor], center: UnitPoint, angle: Angle)

    /// Parse a background string
    /// Formats:
    ///   - Solid: "#FF0000" or "red"
    ///   - Linear: "linear-gradient(to bottom, #FF0000, #0000FF)"
    ///   - Linear: "linear-gradient(45deg, red, blue)"
    ///   - Radial: "radial-gradient(#FF0000, #0000FF)"
    ///   - Angular: "angular-gradient(red, orange, yellow, green, blue, purple, red)"
    public init(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("linear-gradient(") {
            self = Self.parseLinearGradient(trimmed) ?? .solid(CSSColor(string))
        } else if trimmed.hasPrefix("radial-gradient(") {
            self = Self.parseRadialGradient(trimmed) ?? .solid(CSSColor(string))
        } else if trimmed.hasPrefix("angular-gradient(") || trimmed.hasPrefix("conic-gradient(") {
            self = Self.parseAngularGradient(trimmed) ?? .solid(CSSColor(string))
        } else {
            self = .solid(CSSColor(string))
        }
    }

    /// Raw string representation for serialization
    public var rawValue: String {
        switch self {
        case .solid(let color):
            return color.rawValue
        case .linearGradient(let colors, let start, let end):
            let colorStrings = colors.map(\.rawValue).joined(separator: ", ")
            let direction = Self.directionString(from: start, to: end)
            return "linear-gradient(\(direction), \(colorStrings))"
        case .radialGradient(let colors, _, _, _):
            let colorStrings = colors.map(\.rawValue).joined(separator: ", ")
            return "radial-gradient(\(colorStrings))"
        case .angularGradient(let colors, _, _):
            let colorStrings = colors.map(\.rawValue).joined(separator: ", ")
            return "angular-gradient(\(colorStrings))"
        }
    }

    /// Convert to SwiftUI ShapeStyle for filling
    @MainActor
    public func shapeStyle(in rect: CGRect) -> AnyShapeStyle {
        switch self {
        case .solid(let cssColor):
            return AnyShapeStyle(cssColor.color() ?? .white)

        case .linearGradient(let colors, let startPoint, let endPoint):
            let swiftUIColors = colors.compactMap { $0.color() }
            let gradient = LinearGradient(
                colors: swiftUIColors.isEmpty ? [.white] : swiftUIColors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            return AnyShapeStyle(gradient)

        case .radialGradient(let colors, let center, let startRadius, let endRadius):
            let swiftUIColors = colors.compactMap { $0.color() }
            let size = min(rect.width, rect.height)
            let gradient = RadialGradient(
                colors: swiftUIColors.isEmpty ? [.white] : swiftUIColors,
                center: center,
                startRadius: startRadius * size,
                endRadius: endRadius * size
            )
            return AnyShapeStyle(gradient)

        case .angularGradient(let colors, let center, let angle):
            let swiftUIColors = colors.compactMap { $0.color() }
            let gradient = AngularGradient(
                colors: swiftUIColors.isEmpty ? [.white] : swiftUIColors,
                center: center,
                angle: angle
            )
            return AnyShapeStyle(gradient)
        }
    }

    // MARK: - Parsing

    private static func parseLinearGradient(_ string: String) -> Background? {
        // linear-gradient(to bottom, #FF0000, #0000FF)
        // linear-gradient(45deg, red, blue)
        // linear-gradient(red, blue) -- defaults to top to bottom

        guard string.hasPrefix("linear-gradient(") && string.hasSuffix(")") else { return nil }
        let inner = String(string.dropFirst("linear-gradient(".count).dropLast())
        let parts = splitGradientArgs(inner)
        guard parts.count >= 2 else { return nil }

        var startPoint: UnitPoint = .top
        var endPoint: UnitPoint = .bottom
        var colorStartIndex = 0

        // Check if first part is a direction
        let firstPart = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
        if firstPart.hasPrefix("to ") {
            if let (start, end) = parseDirection(firstPart) {
                startPoint = start
                endPoint = end
                colorStartIndex = 1
            }
        } else if firstPart.hasSuffix("deg") {
            if let angle = Double(firstPart.dropLast(3)) {
                (startPoint, endPoint) = pointsFromAngle(angle)
                colorStartIndex = 1
            }
        }

        let colorStrings = Array(parts[colorStartIndex...])
        guard colorStrings.count >= 2 else { return nil }

        let colors = colorStrings.map { CSSColor($0.trimmingCharacters(in: .whitespaces)) }
        return .linearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
    }

    private static func parseRadialGradient(_ string: String) -> Background? {
        // radial-gradient(#FF0000, #0000FF)
        guard string.hasPrefix("radial-gradient(") && string.hasSuffix(")") else { return nil }
        let inner = String(string.dropFirst("radial-gradient(".count).dropLast())
        let parts = splitGradientArgs(inner)
        guard parts.count >= 2 else { return nil }

        let colors = parts.map { CSSColor($0.trimmingCharacters(in: .whitespaces)) }
        return .radialGradient(colors: colors, center: .center, startRadius: 0, endRadius: 0.7)
    }

    private static func parseAngularGradient(_ string: String) -> Background? {
        // angular-gradient(red, orange, yellow, green, blue, purple, red)
        // conic-gradient(red, blue)
        let prefix = string.hasPrefix("angular-gradient(") ? "angular-gradient(" : "conic-gradient("
        guard string.hasPrefix(prefix) && string.hasSuffix(")") else { return nil }
        let inner = String(string.dropFirst(prefix.count).dropLast())
        let parts = splitGradientArgs(inner)
        guard parts.count >= 2 else { return nil }

        let colors = parts.map { CSSColor($0.trimmingCharacters(in: .whitespaces)) }
        return .angularGradient(colors: colors, center: .center, angle: .zero)
    }

    /// Split gradient arguments, respecting parentheses (for rgb() etc)
    private static func splitGradientArgs(_ string: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var depth = 0

        for char in string {
            if char == "(" {
                depth += 1
                current.append(char)
            } else if char == ")" {
                depth -= 1
                current.append(char)
            } else if char == "," && depth == 0 {
                parts.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            parts.append(current)
        }
        return parts
    }

    private static func parseDirection(_ direction: String) -> (UnitPoint, UnitPoint)? {
        let dir = direction.trimmingCharacters(in: .whitespaces).lowercased()
        switch dir {
        case "to top": return (.bottom, .top)
        case "to bottom": return (.top, .bottom)
        case "to left": return (.trailing, .leading)
        case "to right": return (.leading, .trailing)
        case "to top left", "to left top": return (.bottomTrailing, .topLeading)
        case "to top right", "to right top": return (.bottomLeading, .topTrailing)
        case "to bottom left", "to left bottom": return (.topTrailing, .bottomLeading)
        case "to bottom right", "to right bottom": return (.topLeading, .bottomTrailing)
        default: return nil
        }
    }

    private static func pointsFromAngle(_ degrees: Double) -> (UnitPoint, UnitPoint) {
        // CSS gradient angles: 0deg = to top, 90deg = to right, etc.
        let radians = (degrees - 90) * .pi / 180
        let dx = cos(radians)
        let dy = sin(radians)

        // Map to unit points
        let startX = 0.5 - dx * 0.5
        let startY = 0.5 + dy * 0.5
        let endX = 0.5 + dx * 0.5
        let endY = 0.5 - dy * 0.5

        return (UnitPoint(x: startX, y: startY), UnitPoint(x: endX, y: endY))
    }

    private static func directionString(from start: UnitPoint, to end: UnitPoint) -> String {
        // Try to match common directions
        if start == .top && end == .bottom { return "to bottom" }
        if start == .bottom && end == .top { return "to top" }
        if start == .leading && end == .trailing { return "to right" }
        if start == .trailing && end == .leading { return "to left" }
        if start == .topLeading && end == .bottomTrailing { return "to bottom right" }
        if start == .topTrailing && end == .bottomLeading { return "to bottom left" }
        if start == .bottomLeading && end == .topTrailing { return "to top right" }
        if start == .bottomTrailing && end == .topLeading { return "to top left" }
        return "to bottom" // default
    }
}

// MARK: - Convenience Static Properties

extension Background {
    public static let white = Background.solid(CSSColor("white"))
    public static let black = Background.solid(CSSColor("black"))
    public static let clear = Background.solid(CSSColor("transparent"))
}

// MARK: - Codable

extension Background: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
