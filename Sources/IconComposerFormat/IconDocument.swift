import Foundation

/// The root document structure of an .icon file.
///
/// Represents the contents of `icon.json` within an .icon bundle.
public struct IconDocument: Codable, Hashable, Sendable {
    /// Color space to use for untagged SVG colors (e.g., "display-p3").
    public var colorSpaceForUntaggedSVGColors: String?

    /// Base fill for the icon background.
    public var fill: IconFill?

    /// Fill specializations for different appearances.
    public var fillSpecializations: [Specialization<IconFill>]?

    /// Layer groups (rendered back to front).
    public var groups: [IconGroup]

    /// Supported platforms for this icon.
    public var supportedPlatforms: SupportedPlatforms?

    public init(
        colorSpaceForUntaggedSVGColors: String? = nil,
        fill: IconFill? = nil,
        fillSpecializations: [Specialization<IconFill>]? = nil,
        groups: [IconGroup] = [],
        supportedPlatforms: SupportedPlatforms? = nil
    ) {
        self.colorSpaceForUntaggedSVGColors = colorSpaceForUntaggedSVGColors
        self.fill = fill
        self.fillSpecializations = fillSpecializations
        self.groups = groups
        self.supportedPlatforms = supportedPlatforms
    }

    enum CodingKeys: String, CodingKey {
        case colorSpaceForUntaggedSVGColors = "color-space-for-untagged-svg-colors"
        case fill
        case fillSpecializations = "fill-specializations"
        case groups
        case supportedPlatforms = "supported-platforms"
    }

    // MARK: - Resolved Values

    /// Returns the fill for the given appearance.
    public func resolvedFill(for appearance: Appearance? = nil) -> IconFill? {
        if let specs = fillSpecializations {
            if let appearance = appearance,
               let match = specs.first(where: { $0.appearance == appearance }) {
                return match.value
            }
            if let match = specs.first(where: { $0.isDefault }) {
                return match.value
            }
        }
        return fill
    }

    // MARK: - Asset References

    /// Returns all asset filenames referenced by this document.
    public var referencedAssets: Set<String> {
        var assets = Set<String>()

        for group in groups {
            for layer in group.layers {
                if let imageName = layer.imageName {
                    assets.insert(imageName)
                }
                if let specs = layer.imageNameSpecializations {
                    for spec in specs {
                        assets.insert(spec.value)
                    }
                }
            }
        }

        return assets
    }
}
