import SwiftUI

/// Position where a label can be placed on the icon
enum LabelPosition: String, CaseIterable, Sendable {
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
enum LabelContent: Sendable {
    case text(String)
    case image(URL)
    case sfSymbol(String)
}

/// A label to overlay on the icon
struct IconLabel: Sendable, Identifiable {
    let id = UUID()
    let content: LabelContent
    let position: LabelPosition
    let backgroundColor: CSSColor
    let foregroundColor: CSSColor
    let rotateContent: Bool

    init(
        content: LabelContent,
        position: LabelPosition,
        backgroundColor: CSSColor = .red,
        foregroundColor: CSSColor = .white,
        rotateContent: Bool = true
    ) {
        self.content = content
        self.position = position
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.rotateContent = rotateContent
    }

    /// Resolved SwiftUI background color
    var resolvedBackgroundColor: Color {
        backgroundColor.color() ?? .red
    }

    /// Resolved SwiftUI foreground color
    var resolvedForegroundColor: Color {
        foregroundColor.color() ?? .white
    }
}
