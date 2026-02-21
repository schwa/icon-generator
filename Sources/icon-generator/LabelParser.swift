import ArgumentParser
import SwiftUI

/// Parses label specifications from CLI arguments.
///
/// Format: `position:content[:bg[:fg[:options]]]`
///
/// Examples:
/// - `topRight:BETA` - Red background, white text (defaults)
/// - `bottom:v1.0:#0000FF` - Blue background, white text
/// - `pillCenter:NEW:#FF0000:#FFFFFF` - Red background, white text
/// - `topLeft:@/path/to/image.png:#00FF00` - Image with green background
/// - `topRight:sf:star.fill:#FF0000` - SF Symbol with red background
/// - `topRight:sf:star.fill:#FFD700:#FFFFFF:norotate` - SF Symbol without rotation
///
/// Content prefixes:
/// - `@` - Image file path
/// - `sf:` - SF Symbol name
/// - (none) - Plain text
///
/// Options (for diagonal corner labels):
/// - `norotate` - Don't rotate content to match diagonal angle
struct LabelSpecification: ExpressibleByArgument, Sendable {
    let label: IconLabel

    init?(argument: String) {
        let parts = argument.split(separator: ":", maxSplits: 5).map(String.init)

        guard parts.count >= 2 else {
            return nil
        }

        guard let position = LabelPosition(rawValue: parts[0]) else {
            return nil
        }

        let content: LabelContent
        let colorStartIndex: Int

        if parts[1] == "sf", parts.count >= 3 {
            // SF Symbol: position:sf:symbol.name[:bg[:fg[:options]]]
            content = .sfSymbol(parts[2])
            colorStartIndex = 3
        } else if parts[1].hasPrefix("@") {
            // Image: position:@/path/to/image[:bg[:fg[:options]]]
            let path = String(parts[1].dropFirst())
            content = .image(URL(fileURLWithPath: path))
            colorStartIndex = 2
        } else {
            // Text: position:text[:bg[:fg[:options]]]
            content = .text(parts[1])
            colorStartIndex = 2
        }

        let backgroundColor: Color
        if parts.count > colorStartIndex, let color = Color(hex: parts[colorStartIndex]) {
            backgroundColor = color
        } else {
            backgroundColor = .red
        }

        let foregroundColor: Color
        if parts.count > colorStartIndex + 1, let color = Color(hex: parts[colorStartIndex + 1]) {
            foregroundColor = color
        } else {
            foregroundColor = .white
        }

        // Check for options
        var rotateContent = true
        if parts.count > colorStartIndex + 2 {
            let options = parts[colorStartIndex + 2].lowercased()
            if options == "norotate" {
                rotateContent = false
            }
        }

        self.label = IconLabel(
            content: content,
            position: position,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            rotateContent: rotateContent
        )
    }
}

extension LabelPosition: ExpressibleByArgument {}
