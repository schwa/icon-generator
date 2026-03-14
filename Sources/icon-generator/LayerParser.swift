import IconRendering
import ArgumentParser
import SwiftUI

/// Parses layer specifications from CLI arguments.
///
/// Format: `position:content[:key=value...]`
///
/// Positions:
/// - `center` - Center content
/// - Label positions: `top`, `bottom`, `left`, `right`, `topLeft`, `topRight`,
///   `bottomLeft`, `bottomRight`, `pillLeft`, `pillCenter`, `pillRight`
///
/// Content:
/// - Plain text: `center:Hello`
/// - SF Symbol: `center:sf:swift`
/// - Image: `center:@/path/to/image.png`
///
/// Options (key=value pairs):
/// - `color` or `fg` - Foreground color (for center and labels)
/// - `bg` - Background color (for labels)
/// - `size` - Size ratio 0.0-1.0 (for center)
/// - `norotate` - Don't rotate content (for diagonal labels)
///
/// Examples:
/// - `center:sf:swift:color=#FFFFFF:size=0.5`
/// - `topRight:BETA:bg=#FF0000:fg=#FFFFFF`
/// - `topLeft:sf:star.fill:bg=#FFD700:norotate`
/// - `pillCenter:NEW:bg=#007AFF`
struct LayerSpecification: ExpressibleByArgument, Sendable {
    enum LayerContent: Sendable {
        case center(CenterContent)
        case label(IconLabel)
    }

    let content: LayerContent
    let rawValue: String

    init?(argument: String) {
        self.rawValue = argument
        // Split on colons, but be careful with sf: prefix
        let parts = Self.splitLayerArgument(argument)

        guard parts.count >= 2 else {
            return nil
        }

        let position = parts[0].lowercased()

        // Parse content (text, sf:symbol, or @image)
        let contentString: String
        let optionsStartIndex: Int

        if parts[1] == "sf", parts.count >= 3 {
            // SF Symbol: position:sf:symbol.name[:options...]
            contentString = "sf:\(parts[2])"
            optionsStartIndex = 3
        } else if parts[1].hasPrefix("@") {
            // Image: position:@/path/to/image[:options...]
            contentString = parts[1]
            optionsStartIndex = 2
        } else {
            // Text: position:text[:options...]
            contentString = parts[1]
            optionsStartIndex = 2
        }

        // Parse options (key=value pairs or flags)
        var options: [String: String] = [:]
        var flags: Set<String> = []

        for i in optionsStartIndex..<parts.count {
            let opt = parts[i]
            if let eqIndex = opt.firstIndex(of: "=") {
                let key = String(opt[..<eqIndex]).lowercased()
                let value = String(opt[opt.index(after: eqIndex)...])
                options[key] = value
            } else {
                flags.insert(opt.lowercased())
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
            case "cap": anchor = .cap
            default: anchor = .center
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
            // Label position
            guard let labelPosition = LabelPosition(rawValue: position) else {
                // Try case-insensitive match
                guard let labelPosition = LabelPosition.allCases.first(where: { $0.rawValue.lowercased() == position }) else {
                    return nil
                }
                self.content = Self.makeLabel(
                    position: labelPosition,
                    contentString: contentString,
                    options: options,
                    flags: flags
                )
                return
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

    /// Split layer argument on colons, handling sf: prefix specially
    private static func splitLayerArgument(_ argument: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var i = argument.startIndex

        while i < argument.endIndex {
            let char = argument[i]
            if char == ":" {
                // Check if this is "sf:" at the start of content
                if current.isEmpty && parts.count == 1 {
                    // This might be "sf:" prefix - peek ahead
                    let remaining = String(argument[i...])
                    if remaining.hasPrefix(":sf:") || (parts.last == "sf") {
                        // "sf" is the content, next part is symbol name
                        parts.append(current)
                        current = ""
                        i = argument.index(after: i)
                        continue
                    }
                }
                parts.append(current)
                current = ""
            } else {
                current.append(char)
            }
            i = argument.index(after: i)
        }
        if !current.isEmpty {
            parts.append(current)
        }
        return parts
    }
}

extension LabelPosition: ExpressibleByArgument {}
