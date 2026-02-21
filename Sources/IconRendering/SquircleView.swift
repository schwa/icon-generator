import SwiftUI

import ArgumentParser
import CoreText

/// A text view that supports different alignment and anchor modes
public struct CenteredText: View {
    public let text: String
    public let fontSize: CGFloat
    public let color: Color
    public let alignment: CenterAlignment
    public let anchor: CenterAnchor

    public var body: some View {
        if alignment == .visual {
            visualAlignedText
        } else {
            typographicAlignedText
        }
    }

    @ViewBuilder
    private var visualAlignedText: some View {
        // Use Canvas to draw with visual centering
        Canvas { context, canvasSize in
            let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor(color),
            ]
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let line = CTLineCreateWithAttributedString(attrString)

            // Get visual bounds (actual glyph pixels)
            let imageBounds = CTLineGetImageBounds(line, nil)

            // Calculate position to center the visual bounds
            let x = (canvasSize.width - imageBounds.width) / 2 - imageBounds.origin.x
            let y = (canvasSize.height - imageBounds.height) / 2 - imageBounds.origin.y

            context.withCGContext { cgContext in
                cgContext.saveGState()
                cgContext.textMatrix = .identity
                // Flip coordinate system and position text
                cgContext.translateBy(x: x, y: canvasSize.height - y)
                cgContext.scaleBy(x: 1, y: -1)
                CTLineDraw(line, cgContext)
                cgContext.restoreGState()
            }
        }
        .frame(width: fontSize * 1.5, height: fontSize * 1.5)
    }

    @ViewBuilder
    private var typographicAlignedText: some View {
        switch anchor {
        case .baseline:
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(color)
                .alignmentGuide(VerticalAlignment.center) { d in
                    d[.lastTextBaseline]
                }
        case .cap:
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(color)
                .alignmentGuide(VerticalAlignment.center) { d in
                    let baseline = d[.lastTextBaseline]
                    let top = d.height
                    return baseline - (top - baseline) * 0.3
                }
        case .center:
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

public enum CenterContentType: Sendable {
    case text(String)
    case image(URL)
    case sfSymbol(String)

    /// Parse a content string into CenterContentType
    /// - "sf:symbol.name" -> .sfSymbol("symbol.name")
    /// - "@/path/to/image" -> .image(URL)
    /// - "text" -> .text("text")
    public static func parse(_ string: String) -> CenterContentType {
        if string.hasPrefix("sf:") {
            return .sfSymbol(String(string.dropFirst(3)))
        } else if string.hasPrefix("@") {
            return .image(URL(fileURLWithPath: String(string.dropFirst())))
        } else {
            return .text(string)
        }
    }
}

/// How to align center content
public enum CenterAlignment: String, CaseIterable, Sendable, Codable, ExpressibleByArgument {
    /// Align based on visual bounding box of the glyph
    case visual
    /// Align based on typographic metrics (default SwiftUI behavior)
    case typographic
}

/// Vertical anchor point for center content
public enum CenterAnchor: String, CaseIterable, Sendable, Codable, ExpressibleByArgument {
    /// Anchor at the baseline
    case baseline
    /// Anchor at the cap height (top of uppercase letters)
    case cap
    /// Anchor at the center of the em square
    case center
}

public struct CenterContent: Sendable {
    public let content: CenterContentType
    public let color: CSSColor
    public let sizeRatio: CGFloat      // 0.0 to 1.0, relative to icon size
    public let alignment: CenterAlignment
    public let anchor: CenterAnchor
    public let yOffset: CGFloat        // -1.0 to 1.0, proportional offset (positive = up)
    public let rotation: Double        // Rotation in degrees (positive = clockwise)

    public init(
        content: CenterContentType,
        color: CSSColor,
        sizeRatio: CGFloat,
        alignment: CenterAlignment = .typographic,
        anchor: CenterAnchor = .center,
        yOffset: CGFloat = 0,
        rotation: Double = 0
    ) {
        self.content = content
        self.color = color
        self.sizeRatio = sizeRatio
        self.alignment = alignment
        self.anchor = anchor
        self.yOffset = yOffset
        self.rotation = rotation
    }

    /// Convenience initializer that parses content string
    public init(
        contentString: String,
        color: CSSColor,
        sizeRatio: CGFloat,
        alignment: CenterAlignment = .typographic,
        anchor: CenterAnchor = .center,
        yOffset: CGFloat = 0,
        rotation: Double = 0
    ) {
        self.content = CenterContentType.parse(contentString)
        self.color = color
        self.sizeRatio = sizeRatio
        self.alignment = alignment
        self.anchor = anchor
        self.yOffset = yOffset
        self.rotation = rotation
    }

    /// Resolved SwiftUI color
    public var resolvedColor: Color {
        color.color() ?? .black
    }
}

public struct SquircleView: View {
    public let background: Background
    public let size: CGFloat
    public let cornerStyle: CornerStyle
    public let cornerRadiusRatio: CGFloat
    public let labels: [IconLabel]
    public let centerContent: CenterContent?

    public init(
        background: Background,
        size: CGFloat,
        cornerStyle: CornerStyle = .squircle,
        cornerRadiusRatio: CGFloat,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) {
        self.background = background
        self.size = size
        self.cornerStyle = cornerStyle
        self.cornerRadiusRatio = cornerRadiusRatio
        self.labels = labels
        self.centerContent = centerContent
    }

    /// Convenience initializer for solid color backgrounds
    public init(
        backgroundColor: CSSColor,
        size: CGFloat,
        cornerStyle: CornerStyle = .squircle,
        cornerRadiusRatio: CGFloat,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) {
        self.background = .solid(backgroundColor)
        self.size = size
        self.cornerStyle = cornerStyle
        self.cornerRadiusRatio = cornerRadiusRatio
        self.labels = labels
        self.centerContent = centerContent
    }

    public var body: some View {
        Canvas { context, canvasSize in
            var renderer = CanvasIconRenderer(
                context: context,
                size: canvasSize,
                cornerRadiusRatio: cornerRadiusRatio
            )
            renderIcon(
                to: &renderer,
                background: background,
                cornerStyle: cornerStyle,
                cornerRadius: cornerRadiusRatio,
                labels: labels,
                centerContent: centerContent
            )
        }
        .frame(width: size, height: size)
    }

}
