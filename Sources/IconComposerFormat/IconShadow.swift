import Foundation

/// Shadow configuration for a layer group.
///
/// Example JSON:
/// ```json
/// {
///   "kind": "neutral",
///   "opacity": 0.5
/// }
/// ```
public struct IconShadow: Codable, Hashable, Sendable {
    /// The type of shadow.
    public enum Kind: String, Codable, Hashable, Sendable {
        /// Neutral gray shadow.
        case neutral = "neutral"

        /// Shadow colored based on the layer content.
        case layerColor = "layer-color"
    }

    /// The shadow type.
    public var kind: Kind

    /// Shadow opacity (0.0 to 1.0).
    public var opacity: Double

    public init(kind: Kind = .neutral, opacity: Double = 0.5) {
        self.kind = kind
        self.opacity = opacity
    }

    /// Default neutral shadow with 50% opacity.
    public static let neutral = IconShadow(kind: .neutral, opacity: 0.5)

    /// Default layer-color shadow with 50% opacity.
    public static let layerColor = IconShadow(kind: .layerColor, opacity: 0.5)
}
