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
    let backgroundColor: Color
    let foregroundColor: Color

    init(
        content: LabelContent,
        position: LabelPosition,
        backgroundColor: Color = .red,
        foregroundColor: Color = .white
    ) {
        self.content = content
        self.position = position
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
}
