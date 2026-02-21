import Foundation

/// A color value supporting multiple color spaces used in .icon files.
///
/// Parses color strings in formats like:
/// - `"extended-srgb:0.0,0.5,1.0,1.0"` (R, G, B, A)
/// - `"display-p3:0.0,0.5,1.0,1.0"` (R, G, B, A)
/// - `"srgb:0.0,0.5,1.0,1.0"` (R, G, B, A)
/// - `"extended-gray:0.5,1.0"` (L, A)
/// - `"gray:0.5,1.0"` (L, A)
public struct IconColor: Hashable, Sendable {
    /// The color space of this color.
    public enum ColorSpace: String, Codable, Hashable, Sendable {
        case srgb = "srgb"
        case extendedSRGB = "extended-srgb"
        case displayP3 = "display-p3"
        case gray = "gray"
        case extendedGray = "extended-gray"

        /// Whether this is a grayscale color space.
        public var isGrayscale: Bool {
            switch self {
            case .gray, .extendedGray:
                return true
            case .srgb, .extendedSRGB, .displayP3:
                return false
            }
        }
    }

    /// The color space.
    public var colorSpace: ColorSpace

    /// Color components. For RGB spaces: [R, G, B, A]. For grayscale: [L, A].
    public var components: [Double]

    /// Creates a color with the specified color space and components.
    public init(colorSpace: ColorSpace, components: [Double]) {
        self.colorSpace = colorSpace
        self.components = components
    }

    /// Parses a color string like "extended-srgb:0.0,0.5,1.0,1.0".
    public init(parsing string: String) throws {
        let parts = string.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else {
            throw IconColorError.invalidFormat(string)
        }

        let colorSpaceString = String(parts[0])
        let componentsString = String(parts[1])

        guard let colorSpace = ColorSpace(rawValue: colorSpaceString) else {
            throw IconColorError.unknownColorSpace(colorSpaceString)
        }

        let componentStrings = componentsString.split(separator: ",")
        let components = try componentStrings.map { componentString -> Double in
            guard let value = Double(componentString) else {
                throw IconColorError.invalidComponent(String(componentString))
            }
            return value
        }

        // Validate component count
        let expectedCount = colorSpace.isGrayscale ? 2 : 4
        guard components.count == expectedCount else {
            throw IconColorError.wrongComponentCount(
                expected: expectedCount,
                actual: components.count,
                colorSpace: colorSpace
            )
        }

        self.colorSpace = colorSpace
        self.components = components
    }

    /// The red component (RGB color spaces only).
    public var red: Double? {
        guard !colorSpace.isGrayscale, components.count >= 3 else {
            return nil
        }
        return components[0]
    }

    /// The green component (RGB color spaces only).
    public var green: Double? {
        guard !colorSpace.isGrayscale, components.count >= 3 else {
            return nil
        }
        return components[1]
    }

    /// The blue component (RGB color spaces only).
    public var blue: Double? {
        guard !colorSpace.isGrayscale, components.count >= 3 else {
            return nil
        }
        return components[2]
    }

    /// The luminance/white component (grayscale color spaces only).
    public var luminance: Double? {
        guard colorSpace.isGrayscale, !components.isEmpty else {
            return nil
        }
        return components[0]
    }

    /// The alpha component.
    public var alpha: Double {
        components.last ?? 1.0
    }

    /// Serializes the color back to string format.
    public var stringValue: String {
        let componentsString = components.map { formatComponent($0) }.joined(separator: ",")
        return "\(colorSpace.rawValue):\(componentsString)"
    }

    private func formatComponent(_ value: Double) -> String {
        // Format to 5 decimal places, matching Apple's format
        let formatted = String(format: "%.5f", value)
        return formatted
    }
}

extension IconColor: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(parsing: string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

/// Errors that can occur when parsing icon colors.
public enum IconColorError: Error, CustomStringConvertible {
    case invalidFormat(String)
    case unknownColorSpace(String)
    case invalidComponent(String)
    case wrongComponentCount(expected: Int, actual: Int, colorSpace: IconColor.ColorSpace)

    public var description: String {
        switch self {
        case .invalidFormat(let string):
            return "Invalid color format: '\(string)'. Expected 'colorspace:components'."
        case .unknownColorSpace(let colorSpace):
            return "Unknown color space: '\(colorSpace)'. Expected srgb, extended-srgb, display-p3, gray, or extended-gray."
        case .invalidComponent(let component):
            return "Invalid color component: '\(component)'. Expected a number."
        case .wrongComponentCount(let expected, let actual, let colorSpace):
            return "Wrong number of components for \(colorSpace.rawValue): expected \(expected), got \(actual)."
        }
    }
}
