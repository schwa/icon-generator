import IconRendering
import ArgumentParser
import SwiftUI

/// Parses layer specifications from CLI arguments.
///
/// Format: `position; content[; key=value...]`
///
/// Parts are separated by semicolons and may include optional whitespace.
///
/// Positions:
/// - `center` - Center content
/// - Label positions: `top`, `bottom`, `left`, `right`, `topLeft`, `topRight`,
///   `bottomLeft`, `bottomRight`, `pillLeft`, `pillCenter`, `pillRight`
///
/// Content:
/// - Plain text: `center; Hello`
/// - SF Symbol:  `center; sf:swift`
/// - Image:      `center; @/path/to/image.png`
///
/// Options (key=value pairs or flags):
/// - `color` or `fg` - Foreground color (for center and labels)
/// - `bg` - Background color (for labels)
/// - `size` - Size ratio 0.0-1.0 (for center)
/// - `norotate` - Don't rotate content (for diagonal labels)
///
/// Examples:
/// - `center; sf:swift; color=#FFFFFF; size=0.5`
/// - `topRight; BETA; bg=#FF0000; fg=#FFFFFF`
/// - `topLeft; sf:star.fill; bg=#FFD700; norotate`
/// - `pillCenter; NEW; bg=#007AFF`
struct LayerSpecification: ExpressibleByArgument, Sendable {
    enum LayerContent: Sendable {
        case center(CenterContent)
        case label(IconLabel)
    }

    let content: LayerContent
    let rawValue: String

    init?(argument: String) {
        self.rawValue = argument

        // Split on semicolons, trim whitespace from each part
        let parts = argument.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }

        guard parts.count >= 2 else {
            return nil
        }

        let position = parts[0].lowercased()
        let contentString = parts[1]

        // Parse options (key=value pairs or bare flags)
        var options: [String: String] = [:]
        var flags: Set<String> = []

        for part in parts.dropFirst(2) {
            if let eqIndex = part.firstIndex(of: "=") {
                let key = String(part[..<eqIndex]).lowercased()
                let value = String(part[part.index(after: eqIndex)...])
                options[key] = value
            } else if !part.isEmpty {
                flags.insert(part.lowercased())
            }
        }

        // Create appropriate layer type
        if position == "center" {
            let color = options["color"] ?? options["fg"] ?? "black"
            let size = options["size"].flatMap { Double($0) } ?? 0.5
            let alignment: CenterAlignment = options["align"] == "visual" ? .visual : .typographic
            let anchor: CenterAnchor
            switch options["anchor"] {
            case "baseline": anchor = .baseline
            case "cap":      anchor = .cap
            default:         anchor = .center
            }
            let yOffset = options["y-offset"].flatMap { Double($0) } ?? 0
            let rotation = options["rotation"].flatMap { Double($0) } ?? 0

            self.content = .center(CenterContent(
                contentString: contentString,
                color: CSSColor(color),
                sizeRatio: size,
                alignment: alignment,
                anchor: anchor,
                yOffset: yOffset,
                rotation: rotation
            ))
        } else {
            guard let labelPosition = LabelPosition(rawValue: position) ??
                    LabelPosition.allCases.first(where: { $0.rawValue.lowercased() == position }) else {
                return nil
            }
            self.content = Self.makeLabel(
                position: labelPosition,
                contentString: contentString,
                options: options,
                flags: flags
            )
        }
    }

    private static func makeLabel(
        position: LabelPosition,
        contentString: String,
        options: [String: String],
        flags: Set<String>
    ) -> LayerContent {
        let bgString = options["bg"] ?? options["background"] ?? "red"
        let fgString = options["fg"] ?? options["color"] ?? options["foreground"] ?? "white"
        let rotateContent = !flags.contains("norotate")
        let rotation = options["rotation"].flatMap { Double($0) } ?? 0

        let labelContent: LabelContent
        if contentString.hasPrefix("sf:") {
            labelContent = .sfSymbol(String(contentString.dropFirst(3)))
        } else if contentString.hasPrefix("@") {
            labelContent = .image(URL(fileURLWithPath: String(contentString.dropFirst())))
        } else {
            labelContent = .text(contentString)
        }

        return .label(IconLabel(
            content: labelContent,
            position: position,
            backgroundColor: Background(bgString),
            foregroundColor: CSSColor(fgString),
            rotateContent: rotateContent,
            rotation: rotation
        ))
    }
}

extension LabelPosition: ExpressibleByArgument {}
