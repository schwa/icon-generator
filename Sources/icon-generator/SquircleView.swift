import SwiftUI

import ArgumentParser
import CoreText

/// A text view that supports different alignment and anchor modes
struct CenteredText: View {
    let text: String
    let fontSize: CGFloat
    let color: Color
    let alignment: CenterAlignment
    let anchor: CenterAnchor

    var body: some View {
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

enum CenterContentType: Sendable {
    case text(String)
    case image(URL)
    case sfSymbol(String)
}

/// How to align center content
enum CenterAlignment: String, CaseIterable, Sendable, Codable, ExpressibleByArgument {
    /// Align based on visual bounding box of the glyph
    case visual
    /// Align based on typographic metrics (default SwiftUI behavior)
    case typographic
}

/// Vertical anchor point for center content
enum CenterAnchor: String, CaseIterable, Sendable, Codable, ExpressibleByArgument {
    /// Anchor at the baseline
    case baseline
    /// Anchor at the cap height (top of uppercase letters)
    case cap
    /// Anchor at the center of the em square
    case center
}

struct CenterContent: Sendable {
    let content: CenterContentType
    let color: CSSColor
    let sizeRatio: CGFloat      // 0.0 to 1.0, relative to icon size
    let alignment: CenterAlignment
    let anchor: CenterAnchor
    let yOffset: CGFloat        // -1.0 to 1.0, proportional offset (positive = up)
    let rotation: Double        // Rotation in degrees (positive = clockwise)

    init(
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
    init(
        contentString: String,
        color: CSSColor,
        sizeRatio: CGFloat,
        alignment: CenterAlignment = .typographic,
        anchor: CenterAnchor = .center,
        yOffset: CGFloat = 0,
        rotation: Double = 0
    ) {
        self.content = parseCenterContentType(contentString)
        self.color = color
        self.sizeRatio = sizeRatio
        self.alignment = alignment
        self.anchor = anchor
        self.yOffset = yOffset
        self.rotation = rotation
    }

    /// Resolved SwiftUI color
    var resolvedColor: Color {
        color.color() ?? .black
    }
}

struct SquircleView: View {
    let background: Background
    let size: CGFloat
    let cornerStyle: CornerStyle
    let cornerRadiusRatio: CGFloat
    let labels: [IconLabel]
    let centerContent: CenterContent?

    init(
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
    init(
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

    var body: some View {
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
