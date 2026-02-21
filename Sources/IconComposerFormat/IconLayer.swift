import Foundation

/// A single layer within an icon group.
///
/// Layers reference image assets (SVG or PNG) and have various rendering properties
/// that can be specialized for different appearances (light/dark/tinted) or idioms.
public struct IconLayer: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID

    /// Layer name (displayed in Icon Composer).
    public var name: String?

    /// Base image asset filename (e.g., "icon.svg").
    public var imageName: String?

    /// Image name specializations for different appearances.
    public var imageNameSpecializations: [Specialization<String>]?

    /// Base fill for the layer.
    public var fill: IconFill?

    /// Fill specializations.
    public var fillSpecializations: [Specialization<IconFill>]?

    /// Base blend mode.
    public var blendMode: IconBlendMode?

    /// Blend mode specializations.
    public var blendModeSpecializations: [Specialization<IconBlendMode>]?

    /// Base opacity (0.0 to 1.0).
    public var opacity: Double?

    /// Opacity specializations.
    public var opacitySpecializations: [Specialization<Double>]?

    /// Whether the layer is hidden.
    public var hidden: Bool?

    /// Hidden specializations.
    public var hiddenSpecializations: [Specialization<Bool>]?

    /// Whether glass effect is enabled (visionOS).
    public var glass: Bool?

    /// Glass specializations.
    public var glassSpecializations: [Specialization<Bool>]?

    /// Base position (scale and translation).
    public var position: IconPosition?

    /// Position specializations.
    public var positionSpecializations: [Specialization<IconPosition>]?

    public init(
        id: UUID = UUID(),
        name: String? = nil,
        imageName: String? = nil,
        fill: IconFill? = nil,
        blendMode: IconBlendMode? = nil,
        opacity: Double? = nil,
        hidden: Bool? = nil,
        glass: Bool? = nil,
        position: IconPosition? = nil
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.fill = fill
        self.blendMode = blendMode
        self.opacity = opacity
        self.hidden = hidden
        self.glass = glass
        self.position = position
    }

    enum CodingKeys: String, CodingKey {
        case name
        case imageName = "image-name"
        case imageNameSpecializations = "image-name-specializations"
        case fill
        case fillSpecializations = "fill-specializations"
        case blendMode = "blend-mode"
        case blendModeSpecializations = "blend-mode-specializations"
        case opacity
        case opacitySpecializations = "opacity-specializations"
        case hidden
        case hiddenSpecializations = "hidden-specializations"
        case glass
        case glassSpecializations = "glass-specializations"
        case position
        case positionSpecializations = "position-specializations"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        self.imageNameSpecializations = try container.decodeIfPresent([Specialization<String>].self, forKey: .imageNameSpecializations)
        self.fill = try container.decodeIfPresent(IconFill.self, forKey: .fill)
        self.fillSpecializations = try container.decodeIfPresent([Specialization<IconFill>].self, forKey: .fillSpecializations)
        self.blendMode = try container.decodeIfPresent(IconBlendMode.self, forKey: .blendMode)
        self.blendModeSpecializations = try container.decodeIfPresent([Specialization<IconBlendMode>].self, forKey: .blendModeSpecializations)
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity)
        self.opacitySpecializations = try container.decodeIfPresent([Specialization<Double>].self, forKey: .opacitySpecializations)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.hiddenSpecializations = try container.decodeIfPresent([Specialization<Bool>].self, forKey: .hiddenSpecializations)
        self.glass = try container.decodeIfPresent(Bool.self, forKey: .glass)
        self.glassSpecializations = try container.decodeIfPresent([Specialization<Bool>].self, forKey: .glassSpecializations)
        self.position = try container.decodeIfPresent(IconPosition.self, forKey: .position)
        self.positionSpecializations = try container.decodeIfPresent([Specialization<IconPosition>].self, forKey: .positionSpecializations)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageName, forKey: .imageName)
        try container.encodeIfPresent(imageNameSpecializations, forKey: .imageNameSpecializations)
        try container.encodeIfPresent(fill, forKey: .fill)
        try container.encodeIfPresent(fillSpecializations, forKey: .fillSpecializations)
        try container.encodeIfPresent(blendMode, forKey: .blendMode)
        try container.encodeIfPresent(blendModeSpecializations, forKey: .blendModeSpecializations)
        try container.encodeIfPresent(opacity, forKey: .opacity)
        try container.encodeIfPresent(opacitySpecializations, forKey: .opacitySpecializations)
        try container.encodeIfPresent(hidden, forKey: .hidden)
        try container.encodeIfPresent(hiddenSpecializations, forKey: .hiddenSpecializations)
        try container.encodeIfPresent(glass, forKey: .glass)
        try container.encodeIfPresent(glassSpecializations, forKey: .glassSpecializations)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encodeIfPresent(positionSpecializations, forKey: .positionSpecializations)
    }

    // MARK: - Resolved Values

    /// Returns the image name for the given appearance.
    public func resolvedImageName(for appearance: Appearance? = nil) -> String? {
        if let specs = imageNameSpecializations {
            // Try appearance-specific first
            if let appearance = appearance,
               let match = specs.first(where: { $0.appearance == appearance }) {
                return match.value
            }
            // Try default
            if let match = specs.first(where: { $0.isDefault }) {
                return match.value
            }
        }
        return imageName
    }

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

    /// Returns whether the layer is hidden for the given appearance.
    public func isHidden(for appearance: Appearance? = nil) -> Bool {
        if let specs = hiddenSpecializations {
            if let appearance = appearance,
               let match = specs.first(where: { $0.appearance == appearance }) {
                return match.value
            }
            if let match = specs.first(where: { $0.isDefault }) {
                return match.value
            }
        }
        return hidden ?? false
    }

    /// Returns the opacity for the given appearance.
    public func resolvedOpacity(for appearance: Appearance? = nil) -> Double {
        if let specs = opacitySpecializations {
            if let appearance = appearance,
               let match = specs.first(where: { $0.appearance == appearance }) {
                return match.value
            }
            if let match = specs.first(where: { $0.isDefault }) {
                return match.value
            }
        }
        return opacity ?? 1.0
    }
}
