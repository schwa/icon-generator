import ArgumentParser
import CoreText
import Foundation
import IconComposerFormat
import IconRendering
import SwiftUI
import SVGXML

/// Shadow style options for .icon bundles.
enum ShadowStyle: String, CaseIterable, ExpressibleByArgument {
    case neutral
    case layerColor = "layer-color"

    var iconShadowKind: IconShadow.Kind {
        switch self {
        case .neutral:
            return .neutral
        case .layerColor:
            return .layerColor
        }
    }
}

/// Configuration options for .icon bundle generation.
struct IconBundleOptions {
    /// Translucency value (0.0 to 1.0). If set, enables translucency.
    var translucency: Double?

    /// Shadow style. If nil, defaults to neutral.
    var shadowStyle: ShadowStyle?

    /// Whether to enable glass effect on center content.
    var glass: Bool

    init(translucency: Double? = nil, shadowStyle: ShadowStyle? = nil, glass: Bool = false) {
        self.translucency = translucency
        self.shadowStyle = shadowStyle
        self.glass = glass
    }

    /// Default options.
    static let `default` = IconBundleOptions()
}

/// Generates Apple .icon bundles from icon-generator configurations.
struct IconBundleGenerator {
    /// Generate an .icon bundle at the specified path.
    @MainActor
    static func generate(
        at outputPath: String,
        background: Background,
        labels: [IconLabel],
        centerContent: CenterContent?,
        size: Int = 1024,
        options: IconBundleOptions = .default
    ) throws {
        var document = IconDocument()
        var bundle = IconBundle(document: document)

        // Convert background to IconFill
        document.fill = try convertToIconFill(background)

        // Create the main group
        var layers: [IconLayer] = []

        // Render center content as SVG if present
        if let center = centerContent {
            let svgContent = renderCenterContentSVG(center: center, size: size)
            let assetName = "center.svg"
            bundle.setAsset(name: assetName, data: svgContent.data(using: .utf8)!)

            var layer = IconLayer(name: "center", imageName: assetName)
            layer.glass = options.glass
            layers.append(layer)
        }

        // Render each label as SVG
        for (index, label) in labels.enumerated() {
            let svgContent = renderLabelSVG(label: label, size: size)
            let assetName = "label-\(index)-\(label.position.rawValue).svg"
            bundle.setAsset(name: assetName, data: svgContent.data(using: .utf8)!)

            let layer = IconLayer(name: label.position.rawValue, imageName: assetName)
            layers.append(layer)
        }

        // Create the group with configured settings
        var group = IconGroup(layers: layers)

        // Configure shadow
        let shadowKind = options.shadowStyle?.iconShadowKind ?? .neutral
        group.shadow = IconShadow(kind: shadowKind, opacity: 0.5)

        // Configure translucency
        if let translucencyValue = options.translucency {
            group.translucency = IconTranslucency(enabled: true, value: translucencyValue)
        } else {
            group.translucency = IconTranslucency(enabled: false, value: 0.5)
        }

        group.specular = true

        document.groups = [group]
        document.supportedPlatforms = SupportedPlatforms(
            circles: ["watchOS"],
            squares: .shared
        )

        bundle.document = document

        // Write the bundle
        let url = URL(fileURLWithPath: outputPath)
        try bundle.write(to: url)
    }

    /// Convert icon-generator Background to IconComposerFormat IconFill.
    private static func convertToIconFill(_ background: Background) throws -> IconFill {
        switch background {
        case .solid(let cssColor):
            let color = try parseToIconColor(cssColor)
            return .automaticGradient(color)

        case .linearGradient(let colors, _, _):
            // Use first color for automatic gradient
            if let first = colors.first {
                let color = try parseToIconColor(first)
                return .automaticGradient(color)
            }
            return .automatic

        case .radialGradient(let colors, _, _, _):
            if let first = colors.first {
                let color = try parseToIconColor(first)
                return .automaticGradient(color)
            }
            return .automatic

        case .angularGradient(let colors, _, _):
            if let first = colors.first {
                let color = try parseToIconColor(first)
                return .automaticGradient(color)
            }
            return .automatic
        }
    }

    /// Parse a CSSColor to IconColor.
    private static func parseToIconColor(_ cssColor: CSSColor) throws -> IconColor {
        guard let components = cssColor.parse() else {
            // Fallback to white if parsing fails
            return IconColor(colorSpace: .srgb, components: [1.0, 1.0, 1.0, 1.0])
        }

        // Use sRGB color space
        return IconColor(
            colorSpace: .srgb,
            components: [
                components.red,
                components.green,
                components.blue,
                components.alpha
            ]
        )
    }

    // MARK: - SVG Rendering for .icon Assets
    //
    // These render minimal SVGs with just the content, no background shapes.
    // Icon Composer provides its own squircle mask.

    /// Render center content as standalone SVG (no background, no clip).
    @MainActor
    private static func renderCenterContentSVG(center: CenterContent, size: Int) -> String {
        let iconSize = CGSize(width: size, height: size)
        var doc = SVGDocument(width: iconSize.width, height: iconSize.height)

        let contentSize = iconSize.width * center.sizeRatio
        let yOffsetPoints = contentSize * center.yOffset
        let centerPoint = CGPoint(x: iconSize.width / 2, y: iconSize.height / 2 - yOffsetPoints)
        let foreground = center.resolvedColor.svgString()

        switch center.content {
        case .text(let text):
            addTextElement(
                to: &doc,
                text: text,
                at: centerPoint,
                fontSize: contentSize,
                foreground: foreground,
                rotation: center.rotation
            )

        case .sfSymbol(let name):
            addSFSymbolElement(
                to: &doc,
                name: name,
                at: centerPoint,
                fontSize: contentSize,
                foreground: foreground,
                rotation: center.rotation
            )

        case .image(let url):
            addImageElement(
                to: &doc,
                url: url,
                at: centerPoint,
                size: contentSize,
                rotation: center.rotation
            )
        }

        return doc.render()
    }

    /// Render a label as standalone SVG for .icon bundles.
    /// Uses adjusted geometry since Icon Composer applies squircle mask.
    @MainActor
    private static func renderLabelSVG(label: IconLabel, size: Int) -> String {
        let iconSize = CGSize(width: size, height: size)
        var doc = SVGDocument(width: iconSize.width, height: iconSize.height)
        
        switch label.position {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            renderCornerRibbonForIcon(label: label, size: iconSize, to: &doc)
        case .top, .bottom, .left, .right:
            renderEdgeRibbonForIcon(label: label, size: iconSize, to: &doc)
        case .pillLeft, .pillCenter, .pillRight:
            renderPillForIcon(label: label, size: iconSize, to: &doc)
        }
        
        return doc.render()
    }
    
    /// Render corner ribbon with geometry adjusted for Icon Composer's squircle mask.
    @MainActor
    private static func renderCornerRibbonForIcon(label: IconLabel, size: CGSize, to doc: inout SVGDocument) {
        // Larger diagonal width to account for squircle corner cutoff
        // Standard is 0.35, we use 0.55 so more is visible after mask
        let diagonalWidthRatio: CGFloat = 0.55
        let width = size.width * diagonalWidthRatio
        
        // Build triangle path
        var pathData = ""
        let centroid: CGPoint
        let rotation: Double
        
        // The squircle mask cuts corners. From the template SVG:
        // - Corner paths show cuts at approximately 373 from edges
        // The visible ribbon band center should be positioned considering:
        // - The squircle cuts from corner at ~229 along each axis (where curve intersects diagonal)
        // - We want text centered in the visible part of the ribbon
        // Using ~220 offset from the corner point along each axis for text center
        let textInset: CGFloat = 220
        
        switch label.position {
        case .topRight:
            pathData = "M\(formatNum(size.width)),0L\(formatNum(size.width - width)),0L\(formatNum(size.width)),\(formatNum(width))Z"
            centroid = CGPoint(x: size.width - textInset, y: textInset)
            rotation = 45
        case .topLeft:
            pathData = "M0,0L\(formatNum(width)),0L0,\(formatNum(width))Z"
            centroid = CGPoint(x: textInset, y: textInset)
            rotation = -45
        case .bottomRight:
            pathData = "M\(formatNum(size.width)),\(formatNum(size.height))L\(formatNum(size.width - width)),\(formatNum(size.height))L\(formatNum(size.width)),\(formatNum(size.height - width))Z"
            centroid = CGPoint(x: size.width - textInset, y: size.height - textInset)
            rotation = -45
        case .bottomLeft:
            pathData = "M0,\(formatNum(size.height))L\(formatNum(width)),\(formatNum(size.height))L0,\(formatNum(size.height - width))Z"
            centroid = CGPoint(x: textInset, y: size.height - textInset)
            rotation = 45
        default:
            return
        }
        
        // Add triangle background
        let bgFill = label.backgroundColor.svgFill()
        doc.addElement(XMLElement.path(d: pathData, fill: bgFill))
        
        // Add text at centroid
        let fontSize = size.width * 0.08
        let foreground = label.resolvedForegroundColor.svgString()
        let totalRotation = (label.rotateContent ? rotation : 0) + label.rotation
        
        addLabelContent(label.content, at: centroid, fontSize: fontSize, foreground: foreground, rotation: totalRotation, to: &doc)
    }
    
    /// Render edge ribbon with geometry adjusted for Icon Composer's squircle mask.
    @MainActor
    private static func renderEdgeRibbonForIcon(label: IconLabel, size: CGSize, to doc: inout SVGDocument) {
        let thickness = size.height * 0.15
        let rect: CGRect
        let textRotation: Double
        
        switch label.position {
        case .top:
            rect = CGRect(x: 0, y: 0, width: size.width, height: thickness)
            textRotation = 0
        case .bottom:
            rect = CGRect(x: 0, y: size.height - thickness, width: size.width, height: thickness)
            textRotation = 0
        case .left:
            rect = CGRect(x: 0, y: 0, width: thickness, height: size.height)
            textRotation = -90
        case .right:
            rect = CGRect(x: size.width - thickness, y: 0, width: thickness, height: size.height)
            textRotation = 90
        default:
            return
        }
        
        // Add rectangle background
        let bgFill = label.backgroundColor.svgFill()
        doc.addElement(XMLElement.rect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height, fill: bgFill))
        
        // Add text at center
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let fontSize = size.width * 0.08
        let foreground = label.resolvedForegroundColor.svgString()
        let totalRotation = textRotation + label.rotation
        
        addLabelContent(label.content, at: center, fontSize: fontSize, foreground: foreground, rotation: totalRotation, to: &doc)
    }
    
    /// Render pill label for Icon Composer.
    @MainActor
    private static func renderPillForIcon(label: IconLabel, size: CGSize, to doc: inout SVGDocument) {
        let fontSize = size.width * 0.08
        let pillHeight = size.height * 0.12
        let pillPadding = size.width * 0.05
        
        // Estimate content width
        let contentWidth = estimateLabelContentWidth(label.content, fontSize: fontSize)
        let pillWidth = contentWidth + pillHeight  // Extra padding for rounded ends
        
        // Position based on pill type
        let pillX: CGFloat
        switch label.position {
        case .pillLeft:
            pillX = pillPadding
        case .pillRight:
            pillX = size.width - pillWidth - pillPadding
        default:  // .pillCenter
            pillX = (size.width - pillWidth) / 2
        }
        
        // Position near bottom, accounting for squircle mask
        let pillY = size.height - pillHeight - pillPadding - size.height * 0.05
        
        // Draw pill background
        let bgFill = label.backgroundColor.svgFill()
        doc.addElement(XMLElement.rect(
            x: pillX,
            y: pillY,
            width: pillWidth,
            height: pillHeight,
            rx: pillHeight / 2,
            fill: bgFill
        ))
        
        // Add content centered in pill
        let center = CGPoint(x: pillX + pillWidth / 2, y: pillY + pillHeight / 2)
        let foreground = label.resolvedForegroundColor.svgString()
        
        addLabelContent(label.content, at: center, fontSize: fontSize, foreground: foreground, rotation: label.rotation, to: &doc)
    }
    
    /// Estimate width of label content for pill sizing.
    private static func estimateLabelContentWidth(_ content: LabelContent, fontSize: CGFloat) -> CGFloat {
        switch content {
        case .text(let text):
            // Rough estimate: ~0.6 em per character for bold text
            return CGFloat(text.count) * fontSize * 0.6
        case .sfSymbol:
            return fontSize
        case .image:
            return fontSize
        }
    }
    
    /// Add label content (text or SF Symbol) to SVG document.
    @MainActor
    private static func addLabelContent(_ content: LabelContent, at point: CGPoint, fontSize: CGFloat, foreground: String, rotation: Double, to doc: inout SVGDocument) {
        switch content {
        case .text(let text):
            // Use Core Text to render text as SVG path for proper centering
            addTextAsPath(to: &doc, text: text, at: point, fontSize: fontSize, foreground: foreground, rotation: rotation)
        case .sfSymbol(let name):
            addSFSymbolElement(to: &doc, name: name, at: point, fontSize: fontSize, foreground: foreground, rotation: rotation)
        case .image(let url):
            addImageElement(to: &doc, url: url, at: point, size: fontSize, rotation: rotation)
        }
    }
    
    /// Render text as SVG path using Core Text, properly centered at point.
    @MainActor
    private static func addTextAsPath(to doc: inout SVGDocument, text: String, at point: CGPoint, fontSize: CGFloat, foreground: String, rotation: Double) {
        let font = CTFontCreateWithName("SF Pro Bold" as CFString, fontSize, nil)
        
        let characters = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count)
        
        var advances = [CGSize](repeating: .zero, count: glyphs.count)
        let totalWidth = CTFontGetAdvancesForGlyphs(font, .default, glyphs, &advances, glyphs.count)
        let capHeight = CTFontGetCapHeight(font)
        
        let startX = point.x - totalWidth / 2
        let startY = point.y + capHeight / 2
        
        let path = CGMutablePath()
        var currentX = startX
        
        for (index, glyph) in glyphs.enumerated() {
            if let glyphPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                let transform = CGAffineTransform(translationX: currentX, y: startY)
                    .scaledBy(x: 1, y: -1)
                path.addPath(glyphPath, transform: transform)
            }
            currentX += advances[index].width
        }
        
        let svgPathData = cgPathToSVGPath(path)
        
        let transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        } else {
            transform = nil
        }
        
        var pathElement = XMLElement.path(d: svgPathData, fill: foreground)
        if let transform = transform {
            pathElement.attributes["transform"] = transform
        }
        doc.addElement(pathElement)
    }

    // MARK: - SVG Element Helpers

    private static let fontFamily = "-apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif"

    /// Render text as SVG path using Core Text glyph outlines, properly centered.
    @MainActor
    private static func addTextElement(
        to doc: inout SVGDocument,
        text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double
    ) {
        // Create font
        let font = CTFontCreateWithName("SF Pro Bold" as CFString, fontSize, nil)
        
        // Get glyphs for the text
        let characters = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count)
        
        // Calculate total width and get advances
        var advances = [CGSize](repeating: .zero, count: glyphs.count)
        let totalWidth = CTFontGetAdvancesForGlyphs(font, .default, glyphs, &advances, glyphs.count)
        
        // Get font metrics for vertical centering
        let capHeight = CTFontGetCapHeight(font)
        
        // Calculate starting position to center the text
        // Horizontal: center based on total advance width
        // Vertical: center based on cap height (for capital letters)
        let startX = point.x - totalWidth / 2
        let startY = point.y + capHeight / 2  // SVG y increases downward
        
        // Build path from glyphs
        let path = CGMutablePath()
        var currentX = startX
        
        for (index, glyph) in glyphs.enumerated() {
            if let glyphPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                // Transform: translate to position and flip Y (Core Text uses bottom-left origin)
                let transform = CGAffineTransform(translationX: currentX, y: startY)
                    .scaledBy(x: 1, y: -1)
                path.addPath(glyphPath, transform: transform)
            }
            currentX += advances[index].width
        }
        
        // Convert CGPath to SVG path data
        let svgPathData = cgPathToSVGPath(path)
        
        // Add transform for rotation if needed
        let transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        } else {
            transform = nil
        }
        
        var pathElement = XMLElement.path(d: svgPathData, fill: foreground)
        if let transform = transform {
            pathElement.attributes["transform"] = transform
        }
        doc.addElement(pathElement)
    }
    
    /// Convert a CGPath to SVG path data string.
    private static func cgPathToSVGPath(_ path: CGPath) -> String {
        var svgPath = ""
        
        path.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            let points = element.points
            
            switch element.type {
            case .moveToPoint:
                svgPath += "M\(formatNum(points[0].x)),\(formatNum(points[0].y))"
            case .addLineToPoint:
                svgPath += "L\(formatNum(points[0].x)),\(formatNum(points[0].y))"
            case .addQuadCurveToPoint:
                svgPath += "Q\(formatNum(points[0].x)),\(formatNum(points[0].y)) \(formatNum(points[1].x)),\(formatNum(points[1].y))"
            case .addCurveToPoint:
                svgPath += "C\(formatNum(points[0].x)),\(formatNum(points[0].y)) \(formatNum(points[1].x)),\(formatNum(points[1].y)) \(formatNum(points[2].x)),\(formatNum(points[2].y))"
            case .closeSubpath:
                svgPath += "Z"
            @unknown default:
                break
            }
        }
        
        return svgPath
    }
    
    private static func formatNum(_ n: CGFloat) -> String {
        if n == n.rounded() {
            return String(Int(n))
        }
        return String(format: "%.2f", n)
    }

    @MainActor
    private static func addSFSymbolElement(
        to doc: inout SVGDocument,
        name: String,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double
    ) {
        // Render SF Symbol to PNG and embed as base64
        guard let nsImage = renderSFSymbolToImage(name: name, fontSize: fontSize, color: foreground) else {
            // Fallback: render as text with symbol name
            addTextElement(to: &doc, text: "[\(name)]", at: point, fontSize: fontSize * 0.3, foreground: foreground, rotation: rotation)
            return
        }

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        let base64 = pngData.base64EncodedString()
        let dataURL = "data:image/png;base64,\(base64)"

        let imageWidth = nsImage.size.width
        let imageHeight = nsImage.size.height
        let x = point.x - imageWidth / 2
        let y = point.y - imageHeight / 2

        let transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        } else {
            transform = nil
        }

        doc.addElement(XMLElement.image(
            href: dataURL,
            x: x,
            y: y,
            width: imageWidth,
            height: imageHeight,
            transform: transform
        ))
    }

    @MainActor
    private static func addImageElement(
        to doc: inout SVGDocument,
        url: URL,
        at point: CGPoint,
        size: CGFloat,
        rotation: Double
    ) {
        guard let imageData = try? Data(contentsOf: url) else {
            return
        }

        let mimeType: String
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png":
            mimeType = "image/png"
        case "jpg", "jpeg":
            mimeType = "image/jpeg"
        case "gif":
            mimeType = "image/gif"
        case "svg":
            mimeType = "image/svg+xml"
        default:
            mimeType = "image/png"
        }

        let base64 = imageData.base64EncodedString()
        let dataURL = "data:\(mimeType);base64,\(base64)"

        let x = point.x - size / 2
        let y = point.y - size / 2

        let transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        } else {
            transform = nil
        }

        doc.addElement(XMLElement.image(
            href: dataURL,
            x: x,
            y: y,
            width: size,
            height: size,
            transform: transform
        ))
    }

    @MainActor
    private static func renderSFSymbolToImage(name: String, fontSize: CGFloat, color: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
        guard let baseImage = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
            return nil
        }

        let configuredImage = baseImage.withSymbolConfiguration(config)

        // Parse color and apply tint
        let cssColor = CSSColor(color)
        guard let nsColor = cssColor.color().map({ NSColor($0) }) else {
            return configuredImage
        }

        // Create tinted version
        let finalImage = NSImage(size: configuredImage?.size ?? baseImage.size, flipped: false) { rect in
            configuredImage?.draw(in: rect)
            nsColor.set()
            rect.fill(using: .sourceIn)
            return true
        }

        return finalImage
    }
}
