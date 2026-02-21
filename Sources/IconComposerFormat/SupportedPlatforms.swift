import Foundation

/// Platform targeting for the icon.
///
/// Example JSON:
/// ```json
/// {
///   "circles": ["watchOS"],
///   "squares": "shared"
/// }
/// ```
/// or:
/// ```json
/// {
///   "squares": ["iOS", "macOS", "visionOS"]
/// }
/// ```
public struct SupportedPlatforms: Codable, Hashable, Sendable {
    /// Platforms that use circular icons (e.g., watchOS).
    public var circles: [String]?

    /// Platforms that use square/squircle icons.
    public var squares: SquaresPlatform?

    public init(circles: [String]? = nil, squares: SquaresPlatform? = nil) {
        self.circles = circles
        self.squares = squares
    }

    /// All circular platforms use this icon.
    public static func circlesOnly(_ platforms: [String]) -> SupportedPlatforms {
        SupportedPlatforms(circles: platforms, squares: nil)
    }

    /// All square platforms use this icon (shared).
    public static let sharedSquares = SupportedPlatforms(circles: nil, squares: .shared)

    /// Common configuration: watchOS circles, shared squares.
    public static let allPlatforms = SupportedPlatforms(circles: ["watchOS"], squares: .shared)
}

/// Square/squircle platform targeting.
public enum SquaresPlatform: Codable, Hashable, Sendable {
    /// Shared across all square-icon platforms.
    case shared

    /// Specific platforms only.
    case platforms([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try as string first ("shared")
        if let string = try? container.decode(String.self) {
            if string == "shared" {
                self = .shared
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown squares value: '\(string)'"
                )
            }
            return
        }

        // Try as array
        let platforms = try container.decode([String].self)
        self = .platforms(platforms)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .shared:
            try container.encode("shared")
        case .platforms(let platforms):
            try container.encode(platforms)
        }
    }
}
