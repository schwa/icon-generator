import Foundation

/// A fill value for icon backgrounds and layers.
///
/// Supports various fill types used in .icon files:
/// - `"automatic"` - System automatic fill
/// - `"system-light"` / `"system-dark"` - System appearance fills
/// - `{ "solid": "colorspace:components" }` - Solid color
/// - `{ "automatic-gradient": "colorspace:components" }` - Automatic gradient from color
public enum IconFill: Hashable, Sendable {
    /// System automatic fill.
    case automatic

    /// System light appearance fill.
    case systemLight

    /// System dark appearance fill.
    case systemDark

    /// Solid color fill.
    case solid(IconColor)

    /// Automatic gradient generated from a base color.
    case automaticGradient(IconColor)
}

extension IconFill: Codable {
    private enum CodingKeys: String, CodingKey {
        case solid
        case automaticGradient = "automatic-gradient"
    }

    public init(from decoder: Decoder) throws {
        // Try as string first
        if let container = try? decoder.singleValueContainer(),
           let string = try? container.decode(String.self) {
            switch string {
            case "automatic":
                self = .automatic
            case "system-light":
                self = .systemLight
            case "system-dark":
                self = .systemDark
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown fill value: '\(string)'"
                )
            }
            return
        }

        // Try as object with solid or automatic-gradient
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let colorString = try container.decodeIfPresent(String.self, forKey: .solid) {
            let color = try IconColor(parsing: colorString)
            self = .solid(color)
        } else if let colorString = try container.decodeIfPresent(String.self, forKey: .automaticGradient) {
            let color = try IconColor(parsing: colorString)
            self = .automaticGradient(color)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Fill must be 'automatic', 'system-light', 'system-dark', or object with 'solid' or 'automatic-gradient'"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .automatic:
            var container = encoder.singleValueContainer()
            try container.encode("automatic")

        case .systemLight:
            var container = encoder.singleValueContainer()
            try container.encode("system-light")

        case .systemDark:
            var container = encoder.singleValueContainer()
            try container.encode("system-dark")

        case .solid(let color):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(color.stringValue, forKey: .solid)

        case .automaticGradient(let color):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(color.stringValue, forKey: .automaticGradient)
        }
    }
}
