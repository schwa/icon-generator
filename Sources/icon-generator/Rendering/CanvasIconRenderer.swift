import SwiftUI

/// An IconRenderer implementation that renders to a SwiftUI GraphicsContext (for PNG output)
@MainActor
struct CanvasIconRenderer: IconRenderer {
    var context: GraphicsContext
    let size: CGSize
    let cornerRadiusRatio: CGFloat

    init(context: GraphicsContext, size: CGSize, cornerRadiusRatio: CGFloat) {
        self.context = context
        self.size = size
        self.cornerRadiusRatio = cornerRadiusRatio
    }

    // MARK: - Background

    mutating func renderBackground(
        _ background: Background,
        cornerStyle: CornerStyle,
        cornerRadius: CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)
        let path = IconGeometry.iconPath(in: rect, cornerStyle: cornerStyle, cornerRadius: cornerRadius)
        context.fill(path, with: .style(background.shapeStyle(in: rect)))
    }

    // MARK: - Clipping

    mutating func pushClip(cornerStyle: CornerStyle, cornerRadius: CGFloat) {
        let rect = CGRect(origin: .zero, size: size)
        let path = IconGeometry.iconPath(in: rect, cornerStyle: cornerStyle, cornerRadius: cornerRadius)
        context.clip(to: path)
    }

    mutating func popClip() {
        // Note: GraphicsContext.clip() is not reversible in the traditional sense.
        // In SwiftUI's Canvas, we typically work around this by:
        // 1. Drawing clipped content in order (which we do)
        // 2. Or using separate context copies for isolated drawing
        //
        // For our use case, labels are drawn after clipping and we don't need
        // to "unclip" - the clip just constrains label overflow to the icon shape.
        //
        // If we needed true push/pop, we'd use `var copy = context` before clipping.
    }

    // MARK: - Labels

    mutating func renderLabel(_ label: IconLabel) {
        switch label.position {
        case .top, .bottom, .left, .right:
            renderEdgeRibbon(label)
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            renderCornerRibbon(label)
        case .pillLeft, .pillCenter, .pillRight:
            renderPill(label)
        }
    }

    // MARK: - Edge Ribbons

    private mutating func renderEdgeRibbon(_ label: IconLabel) {
        let rect = IconGeometry.edgeRibbonRect(for: label.position, in: size)
        let path = Path(rect)
        context.fill(path, with: .color(label.resolvedBackgroundColor))

        // Resolve and draw content
        let resolvedContent = resolveContent(label.content, foregroundColor: label.resolvedForegroundColor, rotation: label.rotation)

        switch label.position {
        case .top:
            drawResolved(resolvedContent, at: CGPoint(x: rect.midX, y: rect.midY))

        case .bottom:
            drawResolved(resolvedContent, at: CGPoint(x: rect.midX, y: rect.midY))

        case .left:
            // Rotate -90 degrees for left ribbon
            var rotatedContext = context
            rotatedContext.rotate(by: .degrees(-90))
            drawResolved(resolvedContent, at: CGPoint(x: -size.height / 2, y: rect.midX), in: &rotatedContext)

        case .right:
            // Rotate 90 degrees for right ribbon
            var rotatedContext = context
            rotatedContext.rotate(by: .degrees(90))
            drawResolved(resolvedContent, at: CGPoint(x: size.height / 2, y: -size.width + rect.midX), in: &rotatedContext)

        default:
            break
        }
    }

    // MARK: - Corner Ribbons

    private mutating func renderCornerRibbon(_ label: IconLabel) {
        let path = IconGeometry.cornerRibbonPath(for: label.position, in: size)
        context.fill(path, with: .color(label.resolvedBackgroundColor))

        // Resolve content
        let resolvedContent = resolveContent(label.content, foregroundColor: label.resolvedForegroundColor, rotation: label.rotation)

        // Position at centroid with rotation
        let centroid = IconGeometry.cornerRibbonCentroid(for: label.position, in: size)
        let baseRotation = label.rotateContent ? IconGeometry.cornerRibbonRotation(for: label.position) : .zero

        var drawContext = context
        drawContext.translateBy(x: centroid.x, y: centroid.y)
        drawContext.rotate(by: baseRotation)
        drawResolved(resolvedContent, at: .zero, in: &drawContext)
    }

    // MARK: - Pills

    private mutating func renderPill(_ label: IconLabel) {
        // First resolve content to get its size
        let resolvedContent = resolveContent(label.content, foregroundColor: label.resolvedForegroundColor, rotation: label.rotation)
        let contentSize = resolvedContent.size

        // Calculate pill rect
        let pillRect = IconGeometry.pillRect(
            for: label.position,
            in: size,
            contentSize: contentSize,
            cornerRadiusRatio: cornerRadiusRatio
        )

        // Draw pill background
        let pillPath = Path(roundedRect: pillRect, cornerRadius: pillRect.height / 2)
        context.fill(pillPath, with: .color(label.resolvedBackgroundColor))

        // Draw centered content
        drawResolved(resolvedContent, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
    }

    // MARK: - Center Content

    mutating func renderCenterContent(_ content: CenterContent) {
        let contentSize = size.width * content.sizeRatio
        let yOffsetPoints = contentSize * content.yOffset
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - yOffsetPoints)

        switch content.content {
        case .text(let text):
            renderCenterText(
                text,
                at: center,
                fontSize: contentSize,
                color: content.resolvedColor,
                alignment: content.alignment,
                anchor: content.anchor,
                rotation: content.rotation
            )

        case .sfSymbol(let name):
            renderCenterSymbol(
                name,
                at: center,
                fontSize: contentSize,
                color: content.resolvedColor,
                rotation: content.rotation
            )

        case .image(let url):
            renderCenterImage(
                url,
                at: center,
                size: contentSize,
                rotation: content.rotation
            )
        }
    }

    private mutating func renderCenterText(
        _ text: String,
        at center: CGPoint,
        fontSize: CGFloat,
        color: Color,
        alignment: CenterAlignment,
        anchor: CenterAnchor,
        rotation: Double
    ) {
        // Note: For now, we use simple text resolution.
        // Visual alignment and anchor modes would require more complex handling
        // with CenteredText view, which we can't easily use with resolve().
        // The current SquircleView handles this via the symbols: closure.
        // TODO: Implement full visual/anchor support if needed.

        let resolved = context.resolve(
            Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(color)
        )

        if rotation != 0 {
            var transformedContext = context
            transformedContext.translateBy(x: center.x, y: center.y)
            transformedContext.rotate(by: .degrees(rotation))
            transformedContext.draw(resolved, at: .zero)
        } else {
            context.draw(resolved, at: center)
        }
    }

    private mutating func renderCenterSymbol(
        _ name: String,
        at center: CGPoint,
        fontSize: CGFloat,
        color: Color,
        rotation: Double
    ) {
        // Resolve the base SF Symbol image
        var resolved = context.resolve(Image(systemName: name))
        resolved.shading = .color(color)

        // SF Symbols at default resolution are roughly 17pt
        // Scale to achieve the desired fontSize
        let baseSize: CGFloat = 17
        let scale = fontSize / baseSize

        if rotation != 0 {
            var transformedContext = context
            transformedContext.translateBy(x: center.x, y: center.y)
            transformedContext.rotate(by: .degrees(rotation))
            transformedContext.scaleBy(x: scale, y: scale)
            transformedContext.draw(resolved, at: .zero)
        } else {
            var scaledContext = context
            scaledContext.translateBy(x: center.x, y: center.y)
            scaledContext.scaleBy(x: scale, y: scale)
            scaledContext.draw(resolved, at: .zero)
        }
    }

    private mutating func renderCenterImage(
        _ url: URL,
        at center: CGPoint,
        size contentSize: CGFloat,
        rotation: Double
    ) {
        guard let nsImage = NSImage(contentsOf: url) else { return }

        let image = Image(nsImage: nsImage)
        let resolved = context.resolve(image)

        // Calculate scale to fit the image in contentSize
        let imageSize = resolved.size
        let scale = min(contentSize / imageSize.width, contentSize / imageSize.height)

        if rotation != 0 {
            var transformedContext = context
            transformedContext.translateBy(x: center.x, y: center.y)
            transformedContext.rotate(by: .degrees(rotation))
            transformedContext.scaleBy(x: scale, y: scale)
            transformedContext.draw(resolved, at: .zero)
        } else {
            var scaledContext = context
            scaledContext.translateBy(x: center.x, y: center.y)
            scaledContext.scaleBy(x: scale, y: scale)
            scaledContext.draw(resolved, at: .zero)
        }
    }

    // MARK: - Content Resolution

    /// Resolved content that can be drawn
    private enum ResolvedLabelContent {
        case text(GraphicsContext.ResolvedText)
        case symbol(GraphicsContext.ResolvedImage)
        case image(GraphicsContext.ResolvedImage)

        var size: CGSize {
            switch self {
            case .text(let resolved): return resolved.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
            case .symbol(let resolved): return resolved.size
            case .image(let resolved): return resolved.size
            }
        }
    }

    private func resolveContent(
        _ content: LabelContent,
        foregroundColor: Color,
        rotation: Double
    ) -> ResolvedLabelContent {
        let fontSize = IconGeometry.labelFontSize(for: size)

        switch content {
        case .text(let text):
            let textView = Text(text)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(foregroundColor)
            return .text(context.resolve(textView))

        case .sfSymbol(let name):
            var resolved = context.resolve(Image(systemName: name))
            resolved.shading = .color(foregroundColor)
            // Note: SF Symbol scaling is handled in drawResolved based on fontSize
            return .symbol(resolved)

        case .image(let url):
            if let nsImage = NSImage(contentsOf: url) {
                let resolved = context.resolve(Image(nsImage: nsImage))
                return .image(resolved)
            }
            // Fallback to empty text if image fails to load
            return .text(context.resolve(Text("")))
        }
    }

    private func drawResolved(_ content: ResolvedLabelContent, at point: CGPoint) {
        var mutableContext = context
        drawResolved(content, at: point, in: &mutableContext)
    }

    private func drawResolved(_ content: ResolvedLabelContent, at point: CGPoint, in ctx: inout GraphicsContext) {
        let fontSize = IconGeometry.labelFontSize(for: size)

        switch content {
        case .text(let resolved):
            ctx.draw(resolved, at: point)
        case .symbol(let resolved):
            // Scale SF Symbol to match the label font size
            // Default SF Symbol size is roughly 17pt
            let baseSize: CGFloat = 17
            let scale = fontSize / baseSize
            var scaledContext = ctx
            scaledContext.translateBy(x: point.x, y: point.y)
            scaledContext.scaleBy(x: scale, y: scale)
            scaledContext.draw(resolved, at: .zero)
        case .image(let resolved):
            // Scale image to fit label height
            let targetHeight = size.height * 0.1
            let scale = targetHeight / resolved.size.height
            var scaledContext = ctx
            scaledContext.translateBy(x: point.x, y: point.y)
            scaledContext.scaleBy(x: scale, y: scale)
            scaledContext.draw(resolved, at: .zero)
        }
    }
}
