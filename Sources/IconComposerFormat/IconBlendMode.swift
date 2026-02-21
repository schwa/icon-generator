import Foundation

/// Blend modes for icon layers and groups.
public enum IconBlendMode: String, Codable, Hashable, Sendable {
    case normal
    case multiply
    case screen
    case overlay
    case darken
    case lighten
    case colorDodge = "color-dodge"
    case colorBurn = "color-burn"
    case softLight = "soft-light"
    case hardLight = "hard-light"
    case difference
    case exclusion
    case hue
    case saturation
    case color
    case luminosity
    case plusDarker = "plus-darker"
    case plusLighter = "plus-lighter"
}
