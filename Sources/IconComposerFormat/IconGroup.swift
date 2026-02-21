import Foundation

/// Lighting mode for a layer group.
public enum IconLighting: String, Codable, Hashable, Sendable {
    /// Combined lighting across all layers.
    case combined

    /// Individual lighting per layer.
    case individual
}

/// A group of layers in an icon composition.
///
/// Groups contain one or more layers and have shared rendering properties
/// like shadow, translucency, and blur material.
public struct IconGroup: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID

    /// Group name (displayed in Icon Composer).
    public var name: String?

    /// Layers in this group (rendered back to front).
    public var layers: [IconLayer]

    /// Whether the group is hidden.
    public var hidden: Bool?

    /// Hidden specializations.
    public var hiddenSpecializations: [Specialization<Bool>]?

    /// Base shadow configuration.
    public var shadow: IconShadow?

    /// Shadow specializations.
    public var shadowSpecializations: [Specialization<IconShadow>]?

    /// Base translucency configuration.
    public var translucency: IconTranslucency?

    /// Translucency specializations.
    public var translucencySpecializations: [Specialization<IconTranslucency>]?

    /// Blur material strength (nil or null = disabled).
    public var blurMaterial: Double?

    /// Base opacity (0.0 to 1.0).
    public var opacity: Double?

    /// Opacity specializations.
    public var opacitySpecializations: [Specialization<Double>]?

    /// Blend mode specializations (no base value, only specializations).
    public var blendModeSpecializations: [Specialization<IconBlendMode>]?

    /// Lighting mode.
    public var lighting: IconLighting?

    /// Whether specular highlights are enabled.
    public var specular: Bool?

    /// Specular specializations.
    public var specularSpecializations: [Specialization<Bool>]?

    public init(
        id: UUID = UUID(),
        name: String? = nil,
        layers: [IconLayer] = [],
        hidden: Bool? = nil,
        shadow: IconShadow? = nil,
        translucency: IconTranslucency? = nil,
        blurMaterial: Double? = nil,
        opacity: Double? = nil,
        lighting: IconLighting? = nil,
        specular: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.layers = layers
        self.hidden = hidden
        self.shadow = shadow
        self.translucency = translucency
        self.blurMaterial = blurMaterial
        self.opacity = opacity
        self.lighting = lighting
        self.specular = specular
    }

    enum CodingKeys: String, CodingKey {
        case name
        case layers
        case hidden
        case hiddenSpecializations = "hidden-specializations"
        case shadow
        case shadowSpecializations = "shadow-specializations"
        case translucency
        case translucencySpecializations = "translucency-specializations"
        case blurMaterial = "blur-material"
        case opacity
        case opacitySpecializations = "opacity-specializations"
        case blendModeSpecializations = "blend-mode-specializations"
        case lighting
        case specular
        case specularSpecializations = "specular-specializations"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.layers = try container.decode([IconLayer].self, forKey: .layers)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.hiddenSpecializations = try container.decodeIfPresent([Specialization<Bool>].self, forKey: .hiddenSpecializations)
        self.shadow = try container.decodeIfPresent(IconShadow.self, forKey: .shadow)
        self.shadowSpecializations = try container.decodeIfPresent([Specialization<IconShadow>].self, forKey: .shadowSpecializations)
        self.translucency = try container.decodeIfPresent(IconTranslucency.self, forKey: .translucency)
        self.translucencySpecializations = try container.decodeIfPresent([Specialization<IconTranslucency>].self, forKey: .translucencySpecializations)
        self.blurMaterial = try container.decodeIfPresent(Double.self, forKey: .blurMaterial)
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity)
        self.opacitySpecializations = try container.decodeIfPresent([Specialization<Double>].self, forKey: .opacitySpecializations)
        self.blendModeSpecializations = try container.decodeIfPresent([Specialization<IconBlendMode>].self, forKey: .blendModeSpecializations)
        self.lighting = try container.decodeIfPresent(IconLighting.self, forKey: .lighting)
        self.specular = try container.decodeIfPresent(Bool.self, forKey: .specular)
        self.specularSpecializations = try container.decodeIfPresent([Specialization<Bool>].self, forKey: .specularSpecializations)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(layers, forKey: .layers)
        try container.encodeIfPresent(hidden, forKey: .hidden)
        try container.encodeIfPresent(hiddenSpecializations, forKey: .hiddenSpecializations)
        try container.encodeIfPresent(shadow, forKey: .shadow)
        try container.encodeIfPresent(shadowSpecializations, forKey: .shadowSpecializations)
        try container.encodeIfPresent(translucency, forKey: .translucency)
        try container.encodeIfPresent(translucencySpecializations, forKey: .translucencySpecializations)
        try container.encodeIfPresent(blurMaterial, forKey: .blurMaterial)
        try container.encodeIfPresent(opacity, forKey: .opacity)
        try container.encodeIfPresent(opacitySpecializations, forKey: .opacitySpecializations)
        try container.encodeIfPresent(blendModeSpecializations, forKey: .blendModeSpecializations)
        try container.encodeIfPresent(lighting, forKey: .lighting)
        try container.encodeIfPresent(specular, forKey: .specular)
        try container.encodeIfPresent(specularSpecializations, forKey: .specularSpecializations)
    }

    // MARK: - Resolved Values

    /// Returns whether the group is hidden for the given appearance.
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

    /// Returns the shadow for the given appearance.
    public func resolvedShadow(for appearance: Appearance? = nil) -> IconShadow? {
        if let specs = shadowSpecializations {
            if let appearance = appearance,
               let match = specs.first(where: { $0.appearance == appearance }) {
                return match.value
            }
            if let match = specs.first(where: { $0.isDefault }) {
                return match.value
            }
        }
        return shadow
    }

    /// Returns the translucency for the given appearance.
    public func resolvedTranslucency(for appearance: Appearance? = nil) -> IconTranslucency? {
        if let specs = translucencySpecializations {
            if let appearance = appearance,
               let match = specs.first(where: { $0.appearance == appearance }) {
                return match.value
            }
            if let match = specs.first(where: { $0.isDefault }) {
                return match.value
            }
        }
        return translucency
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
