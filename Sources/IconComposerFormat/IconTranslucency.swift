import Foundation

/// Translucency settings for a layer group (visionOS glass effect).
///
/// Example JSON:
/// ```json
/// {
///   "enabled": true,
///   "value": 0.5
/// }
/// ```
public struct IconTranslucency: Codable, Hashable, Sendable {
    /// Whether translucency is enabled.
    public var enabled: Bool

    /// Translucency amount (0.0 to 1.0).
    public var value: Double

    public init(enabled: Bool = false, value: Double = 0.5) {
        self.enabled = enabled
        self.value = value
    }

    /// Disabled translucency.
    public static let disabled = IconTranslucency(enabled: false, value: 0.5)

    /// Default enabled translucency at 50%.
    public static let `default` = IconTranslucency(enabled: true, value: 0.5)
}
