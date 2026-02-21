import Foundation

/// Position and scale for a layer within the icon.
///
/// Example JSON:
/// ```json
/// {
///   "scale": 1.25,
///   "translation-in-points": [0, 14]
/// }
/// ```
public struct IconPosition: Codable, Hashable, Sendable {
    /// Scale factor (1.0 = original size).
    public var scale: Double

    /// Translation offset in points [x, y].
    public var translationInPoints: [Double]

    /// The X translation in points.
    public var translationX: Double {
        translationInPoints.first ?? 0
    }

    /// The Y translation in points.
    public var translationY: Double {
        translationInPoints.count > 1 ? translationInPoints[1] : 0
    }

    public init(scale: Double = 1.0, translationInPoints: [Double] = [0, 0]) {
        self.scale = scale
        self.translationInPoints = translationInPoints
    }

    public init(scale: Double = 1.0, translationX: Double = 0, translationY: Double = 0) {
        self.scale = scale
        self.translationInPoints = [translationX, translationY]
    }

    enum CodingKeys: String, CodingKey {
        case scale
        case translationInPoints = "translation-in-points"
    }

    /// The identity position (no transformation).
    public static let identity = IconPosition(scale: 1.0, translationInPoints: [0, 0])
}
