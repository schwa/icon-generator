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

    private let centerContentID = "centerContent"

    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let cornerRadius = min(canvasSize.width, canvasSize.height) * cornerRadiusRatio
            let squirclePath: Path
            if let style = cornerStyle.roundedCornerStyle {
                squirclePath = Path(roundedRect: rect, cornerRadius: cornerRadius, style: style)
            } else {
                squirclePath = Path(rect)
            }

            // Fill background
            context.fill(squirclePath, with: .style(background.shapeStyle(in: rect)))

            // Draw center content (before clipping so it's not affected by label clip)
            if centerContent != nil, let symbol = context.resolveSymbol(id: centerContentID) {
                context.draw(symbol, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2))
            }

            // Clip all subsequent drawing to the squircle
            context.clip(to: squirclePath)

            // Draw each label
            for label in labels {
                drawLabel(label, in: context, canvasSize: canvasSize, cornerRadiusRatio: cornerRadiusRatio)
            }
        } symbols: {
            // Center content symbol
            if let center = centerContent {
                centerContentView(for: center)
                    .tag(centerContentID)
            }

            // Create symbols for each label's content
            ForEach(labels) { label in
                labelContentView(for: label)
                    .tag(label.id)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func centerContentView(for center: CenterContent) -> some View {
        let contentSize = size * center.sizeRatio
        let yOffsetPoints = contentSize * center.yOffset

        switch center.content {
        case .text(let text):
            CenteredText(
                text: text,
                fontSize: contentSize,
                color: center.resolvedColor,
                alignment: center.alignment,
                anchor: center.anchor
            )
            .rotationEffect(.degrees(center.rotation))
            .offset(y: -yOffsetPoints)
        case .image(let url):
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: contentSize, height: contentSize)
                    .rotationEffect(.degrees(center.rotation))
                    .offset(y: -yOffsetPoints)
            }
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: contentSize, weight: .bold))
                .foregroundStyle(center.resolvedColor)
                .rotationEffect(.degrees(center.rotation))
                .offset(y: -yOffsetPoints)
        }
    }

    @ViewBuilder
    private func labelContentView(for label: IconLabel) -> some View {
        switch label.content {
        case .text(let text):
            Text(text)
                .font(.system(size: size * 0.08, weight: .bold))
                .foregroundStyle(label.resolvedForegroundColor)
                .rotationEffect(.degrees(label.rotation))
        case .image(let url):
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: size * 0.1)
                    .foregroundStyle(label.resolvedForegroundColor)
                    .rotationEffect(.degrees(label.rotation))
            }
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.08, weight: .bold))
                .foregroundStyle(label.resolvedForegroundColor)
                .rotationEffect(.degrees(label.rotation))
        }
    }

    private func drawLabel(_ label: IconLabel, in context: GraphicsContext, canvasSize: CGSize, cornerRadiusRatio: CGFloat) {
        let ribbonThickness = canvasSize.height * 0.15
        let pillHeight = canvasSize.height * 0.12
        let pillPadding = canvasSize.width * 0.05
        // For corner pills, we need extra horizontal padding to clear the squircle corners
        // Use the corner radius plus a small margin to ensure pills don't get clipped
        let cornerSafePadding = canvasSize.width * (cornerRadiusRatio * 0.6 + 0.02)
        let diagonalWidth = canvasSize.width * 0.35

        switch label.position {
        // Edge ribbons
        case .top:
            let rect = CGRect(x: 0, y: 0, width: canvasSize.width, height: ribbonThickness)
            context.fill(Path(rect), with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                context.draw(symbol, at: CGPoint(x: canvasSize.width / 2, y: ribbonThickness / 2))
            }

        case .bottom:
            let rect = CGRect(x: 0, y: canvasSize.height - ribbonThickness, width: canvasSize.width, height: ribbonThickness)
            context.fill(Path(rect), with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                context.draw(symbol, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height - ribbonThickness / 2))
            }

        case .left:
            let rect = CGRect(x: 0, y: 0, width: ribbonThickness, height: canvasSize.height)
            context.fill(Path(rect), with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                var rotatedContext = context
                rotatedContext.rotate(by: .degrees(-90))
                rotatedContext.draw(symbol, at: CGPoint(x: -canvasSize.height / 2, y: ribbonThickness / 2))
            }

        case .right:
            let rect = CGRect(x: canvasSize.width - ribbonThickness, y: 0, width: ribbonThickness, height: canvasSize.height)
            context.fill(Path(rect), with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                var rotatedContext = context
                rotatedContext.rotate(by: .degrees(90))
                rotatedContext.draw(symbol, at: CGPoint(x: canvasSize.height / 2, y: -canvasSize.width + ribbonThickness / 2))
            }

        // Diagonal corner ribbons
        case .topLeft:
            let path = diagonalRibbonPath(corner: .topLeft, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (0,0), (w,0), (0,w) is (w/3, w/3)
                let centroid = CGPoint(x: diagonalWidth / 3, y: diagonalWidth / 3)
                var drawContext = context
                drawContext.translateBy(x: centroid.x, y: centroid.y)
                if label.rotateContent {
                    drawContext.rotate(by: .degrees(-45))
                }
                drawContext.draw(symbol, at: .zero)
            }

        case .topRight:
            let path = diagonalRibbonPath(corner: .topRight, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (w,0), (w-d,0), (w,d)
                let centroid = CGPoint(
                    x: canvasSize.width - diagonalWidth / 3,
                    y: diagonalWidth / 3
                )
                var drawContext = context
                drawContext.translateBy(x: centroid.x, y: centroid.y)
                if label.rotateContent {
                    drawContext.rotate(by: .degrees(45))
                }
                drawContext.draw(symbol, at: .zero)
            }

        case .bottomLeft:
            let path = diagonalRibbonPath(corner: .bottomLeft, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (0,h), (d,h), (0,h-d)
                let centroid = CGPoint(
                    x: diagonalWidth / 3,
                    y: canvasSize.height - diagonalWidth / 3
                )
                var drawContext = context
                drawContext.translateBy(x: centroid.x, y: centroid.y)
                if label.rotateContent {
                    drawContext.rotate(by: .degrees(45))
                }
                drawContext.draw(symbol, at: .zero)
            }

        case .bottomRight:
            let path = diagonalRibbonPath(corner: .bottomRight, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.resolvedBackgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (w,h), (w-d,h), (w,h-d)
                let centroid = CGPoint(
                    x: canvasSize.width - diagonalWidth / 3,
                    y: canvasSize.height - diagonalWidth / 3
                )
                var drawContext = context
                drawContext.translateBy(x: centroid.x, y: centroid.y)
                if label.rotateContent {
                    drawContext.rotate(by: .degrees(-45))
                }
                drawContext.draw(symbol, at: .zero)
            }

        // Pill overlays
        case .pillLeft:
            if let symbol = context.resolveSymbol(id: label.id) {
                let symbolSize = symbol.size
                let pillWidth = symbolSize.width + pillPadding * 2
                let pillRect = CGRect(
                    x: cornerSafePadding,
                    y: canvasSize.height - pillHeight - pillPadding,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
                context.fill(pillPath, with: .color(label.resolvedBackgroundColor))
                context.draw(symbol, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
            }

        case .pillCenter:
            if let symbol = context.resolveSymbol(id: label.id) {
                let symbolSize = symbol.size
                let pillWidth = symbolSize.width + pillPadding * 2
                let pillRect = CGRect(
                    x: (canvasSize.width - pillWidth) / 2,
                    y: canvasSize.height - pillHeight - pillPadding,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
                context.fill(pillPath, with: .color(label.resolvedBackgroundColor))
                context.draw(symbol, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
            }

        case .pillRight:
            if let symbol = context.resolveSymbol(id: label.id) {
                let symbolSize = symbol.size
                let pillWidth = symbolSize.width + pillPadding * 2
                let pillRect = CGRect(
                    x: canvasSize.width - pillWidth - cornerSafePadding,
                    y: canvasSize.height - pillHeight - pillPadding,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
                context.fill(pillPath, with: .color(label.resolvedBackgroundColor))
                context.draw(symbol, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
            }
        }
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func diagonalRibbonPath(corner: Corner, size: CGSize, width: CGFloat) -> Path {
        var path = Path()

        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: width))
            path.closeSubpath()

        case .topRight:
            path.move(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width - width, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: width))
            path.closeSubpath()

        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height - width))
            path.closeSubpath()

        case .bottomRight:
            path.move(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: size.width - width, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height - width))
            path.closeSubpath()
        }

        return path
    }
}
