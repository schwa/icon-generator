import Foundation

/// Appearance modes for specializations.
public enum Appearance: String, Codable, Hashable, Sendable {
    case light
    case dark
    case tinted
}

/// Device idioms for specializations.
public enum Idiom: String, Codable, Hashable, Sendable {
    case square
    case macOS
    case iOS
    case watchOS
    case visionOS
}

/// A specialization of a value for a specific appearance or idiom.
///
/// Specializations allow different values based on:
/// - Appearance: light, dark, tinted
/// - Idiom: square, macOS, iOS, watchOS, visionOS
///
/// Example JSON:
/// ```json
/// { "appearance": "dark", "value": 0.5 }
/// { "idiom": "macOS", "value": true }
/// ```
public struct Specialization<Value: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {
    /// The specialized value.
    public var value: Value

    /// The appearance this specialization applies to, if any.
    public var appearance: Appearance?

    /// The idiom this specialization applies to, if any.
    public var idiom: Idiom?

    public init(value: Value, appearance: Appearance? = nil, idiom: Idiom? = nil) {
        self.value = value
        self.appearance = appearance
        self.idiom = idiom
    }

    /// Whether this is the default (unspecialized) value.
    public var isDefault: Bool {
        appearance == nil && idiom == nil
    }

    /// Whether this specialization matches the given criteria.
    public func matches(appearance: Appearance? = nil, idiom: Idiom? = nil) -> Bool {
        let appearanceMatches = self.appearance == nil || self.appearance == appearance
        let idiomMatches = self.idiom == nil || self.idiom == idiom
        return appearanceMatches && idiomMatches
    }
}

/// A property that can have a base value and/or specializations.
///
/// Used for properties like opacity, hidden, fill that can vary by appearance/idiom.
///
/// Example JSON patterns:
/// ```json
/// // Just base value
/// "opacity": 0.5
///
/// // Just specializations
/// "opacity-specializations": [
///   { "value": 1.0 },
///   { "appearance": "dark", "value": 0.5 }
/// ]
///
/// // Both (base value can be overridden by specializations)
/// "opacity": 0.5,
/// "opacity-specializations": [{ "appearance": "dark", "value": 0.3 }]
/// ```
public struct SpecializableProperty<Value: Codable & Hashable & Sendable>: Hashable, Sendable {
    /// The base value, used when no specialization matches.
    public var base: Value?

    /// Specializations for different appearances/idioms.
    public var specializations: [Specialization<Value>]

    public init(base: Value? = nil, specializations: [Specialization<Value>] = []) {
        self.base = base
        self.specializations = specializations
    }

    /// Creates a property with just a base value.
    public init(_ value: Value) {
        self.base = value
        self.specializations = []
    }

    /// Returns the value for the given appearance and idiom.
    ///
    /// Resolution order:
    /// 1. Specialization matching both appearance and idiom
    /// 2. Specialization matching appearance only
    /// 3. Specialization matching idiom only
    /// 4. Default specialization (no appearance/idiom)
    /// 5. Base value
    public func value(for appearance: Appearance? = nil, idiom: Idiom? = nil) -> Value? {
        // Try exact match first
        if let match = specializations.first(where: { $0.appearance == appearance && $0.idiom == idiom }) {
            return match.value
        }

        // Try appearance-only match
        if appearance != nil {
            if let match = specializations.first(where: { $0.appearance == appearance && $0.idiom == nil }) {
                return match.value
            }
        }

        // Try idiom-only match
        if idiom != nil {
            if let match = specializations.first(where: { $0.appearance == nil && $0.idiom == idiom }) {
                return match.value
            }
        }

        // Try default specialization
        if let defaultSpec = specializations.first(where: { $0.isDefault }) {
            return defaultSpec.value
        }

        // Fall back to base value
        return base
    }

    /// Whether this property has any value (base or specializations).
    public var hasValue: Bool {
        base != nil || !specializations.isEmpty
    }
}

extension SpecializableProperty: Codable {
    public init(from decoder: Decoder) throws {
        // This is typically decoded field-by-field in the parent type
        // (e.g., "opacity" and "opacity-specializations" as separate keys)
        // So this just handles the case of a single value
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Value.self) {
            self.base = value
            self.specializations = []
        } else {
            self.base = nil
            self.specializations = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        // Encoding is handled by the parent type
        var container = encoder.singleValueContainer()
        if let base = base {
            try container.encode(base)
        }
    }
}
