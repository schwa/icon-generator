import SwiftUI

/// Position where a label can be placed on the icon
public enum LabelPosition: String, CaseIterable, Sendable {
    // Ribbon/banner style along edges
    case top
    case bottom
    case left
    case right

    // Diagonal corner ribbons
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    // Pill overlays along bottom
    case pillLeft
    case pillCenter
    case pillRight
}

/// Content type for a label
public enum LabelContent: Sendable {
    case text(String)
    case image(URL)
    case sfSymbol(String)

    /// Parse a content string into LabelContent
    /// - "sf:symbol.name" -> .sfSymbol("symbol.name")
    /// - "@/path/to/image" -> .image(URL)
    /// - "text" -> .text("text")
    public static func parse(_ string: String) -> LabelContent {
        if string.hasPrefix("sf:") {
            return .sfSymbol(String(string.dropFirst(3)))
        } else if string.hasPrefix("@") {
            return .image(URL(fileURLWithPath: String(string.dropFirst())))
        } else {
            return .text(string)
        }
    }
}

/// A label to overlay on the icon
public struct IconLabel: Sendable, Identifiable {
    public let id = UUID()
    public let content: LabelContent
    public let position: LabelPosition
    public let backgroundColor: CSSColor
    public let foregroundColor: CSSColor
    public let rotateContent: Bool
    public let rotation: Double        // Additional rotation in degrees (positive = clockwise)

    public init(
        content: LabelContent,
        position: LabelPosition,
        backgroundColor: CSSColor = .red,
        foregroundColor: CSSColor = .white,
        rotateContent: Bool = true,
        rotation: Double = 0
    ) {
        self.content = content
        self.position = position
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.rotateContent = rotateContent
        self.rotation = rotation
    }

    /// Resolved SwiftUI background color
    public var resolvedBackgroundColor: Color {
        backgroundColor.color() ?? .red
    }

    /// Resolved SwiftUI foreground color
    public var resolvedForegroundColor: Color {
        foregroundColor.color() ?? .white
    }
}
