import SwiftUI
import AppKit
import SVGXML

/// An IconRenderer implementation that renders to an SVG document
@MainActor
public struct SVGIconRenderer: IconRenderer {
    /// Default font family for SVG text elements
    public static let defaultFontFamily = "-apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif"

    public var document: SVGDocument
    public let size: CGSize
    public let cornerRadiusRatio: CGFloat
    public let fontFamily: String

    private var clipPathID: String?
    private var gradientID: String?

    public init(size: CGSize, cornerRadiusRatio: CGFloat, fontFamily: String = defaultFontFamily) {
        self.document = SVGDocument(width: size.width, height: size.height)
        self.size = size
        self.cornerRadiusRatio = cornerRadiusRatio
        self.fontFamily = fontFamily
    }

    // MARK: - Background

    public mutating func renderBackground(
        _ background: Background,
        cornerStyle: CornerStyle,
        cornerRadius: CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)
        let path = IconGeometry.iconPath(in: rect, cornerStyle: cornerStyle, cornerRadius: cornerRadius)
        let pathData = path.svgPathData()

        // Add gradient to defs if needed
        let fill: String
        if let fillRef = document.addGradient(from: background) {
            gradientID = fillRef
            fill = fillRef
        } else {
            fill = background.svgFill()
        }

        document.addElement(XMLElement.path(d: pathData, fill: fill))
    }

    // MARK: - Clipping

    public mutating func pushClip(cornerStyle: CornerStyle, cornerRadius: CGFloat) {
        let rect = CGRect(origin: .zero, size: size)
        let path = IconGeometry.iconPath(in: rect, cornerStyle: cornerStyle, cornerRadius: cornerRadius)
        clipPathID = document.addClipPath(path: path)
    }

    public mutating func popClip() {
        clipPathID = nil
    }

    // MARK: - Labels

    public mutating func renderLabel(_ label: IconLabel) {
        switch label.position {
        case .top, .bottom, .left, .right:
            renderEdgeRibbon(label)
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            renderCornerRibbon(label)
        case .pillLeft, .pillCenter, .pillRight:
            renderPill(label)
        }
    }

    // MARK: - Fill Helper

    private mutating func fillString(for background: Background) -> String {
        if let fillRef = document.addGradient(from: background) {
            return fillRef
        } else {
            return background.svgFill()
        }
    }

    // MARK: - Edge Ribbons

    private mutating func renderEdgeRibbon(_ label: IconLabel) {
        let rect = IconGeometry.edgeRibbonRect(for: label.position, in: size)
        let fill = fillString(for: label.backgroundColor)

        // Background rect (clipped to icon shape)
        var rectElement = XMLElement.rect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height,
            fill: fill
        )
        if let clipID = clipPathID {
            rectElement.attributes["clip-path"] = "url(#\(clipID))"
        }
        document.addElement(rectElement)

        // Content
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let fontSize = IconGeometry.labelFontSize(for: size)
        let foreground = label.resolvedForegroundColor.svgString()

        switch label.position {
        case .left:
            addLabelContent(
                label.content,
                at: center,
                fontSize: fontSize,
                foreground: foreground,
                rotation: -90,
                rotateContent: label.rotation
            )
        case .right:
            addLabelContent(
                label.content,
                at: center,
                fontSize: fontSize,
                foreground: foreground,
                rotation: 90,
                rotateContent: label.rotation
            )
        default:
            addLabelContent(
                label.content,
                at: center,
                fontSize: fontSize,
                foreground: foreground,
                rotation: 0,
                rotateContent: label.rotation
            )
        }
    }

    // MARK: - Corner Ribbons

    private mutating func renderCornerRibbon(_ label: IconLabel) {
        let path = IconGeometry.cornerRibbonPath(for: label.position, in: size)
        let pathData = path.svgPathData()
        let fill = fillString(for: label.backgroundColor)

        // Background triangle (clipped to icon shape)
        var pathElement = XMLElement.path(d: pathData, fill: fill)
        if let clipID = clipPathID {
            pathElement.attributes["clip-path"] = "url(#\(clipID))"
        }
        document.addElement(pathElement)

        // Content at centroid
        let centroid = IconGeometry.cornerRibbonCentroid(for: label.position, in: size)
        let baseRotation = label.rotateContent ? IconGeometry.cornerRibbonRotation(for: label.position).degrees : 0
        let fontSize = IconGeometry.labelFontSize(for: size)
        let foreground = label.resolvedForegroundColor.svgString()

        addLabelContent(
            label.content,
            at: centroid,
            fontSize: fontSize,
            foreground: foreground,
            rotation: baseRotation,
            rotateContent: label.rotation
        )
    }

    // MARK: - Pills

    private mutating func renderPill(_ label: IconLabel) {
        let fontSize = IconGeometry.labelFontSize(for: size)

        // Estimate content size for pill sizing
        let contentSize = estimateContentSize(label.content, fontSize: fontSize)

        // Calculate pill rect
        let pillRect = IconGeometry.pillRect(
            for: label.position,
            in: size,
            contentSize: contentSize,
            cornerRadiusRatio: cornerRadiusRatio
        )

        // Draw pill background
        let fill = fillString(for: label.backgroundColor)
        var pillElement = XMLElement.rect(
            x: pillRect.minX,
            y: pillRect.minY,
            width: pillRect.width,
            height: pillRect.height,
            rx: pillRect.height / 2,
            fill: fill
        )
        if let clipID = clipPathID {
            pillElement.attributes["clip-path"] = "url(#\(clipID))"
        }
        document.addElement(pillElement)

        // Content centered in pill
        let center = CGPoint(x: pillRect.midX, y: pillRect.midY)
        let foreground = label.resolvedForegroundColor.svgString()

        addLabelContent(
            label.content,
            at: center,
            fontSize: fontSize,
            foreground: foreground,
            rotation: 0,
            rotateContent: label.rotation
        )
    }

    // MARK: - Center Content

    public mutating func renderCenterContent(_ content: CenterContent) {
        let contentSize = size.width * content.sizeRatio
        let yOffsetPoints = contentSize * content.yOffset
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - yOffsetPoints)
        let foreground = content.resolvedColor.svgString()

        switch content.content {
        case .text(let text):
            addTextElement(
                text,
                at: center,
                fontSize: contentSize,
                foreground: foreground,
                rotation: content.rotation
            )

        case .sfSymbol(let name):
            addSFSymbolElement(
                name,
                at: center,
                fontSize: contentSize,
                foreground: foreground,
                rotation: content.rotation
            )

        case .image(let url):
            addImageElement(
                url,
                at: center,
                size: contentSize,
                rotation: content.rotation
            )
        }
    }

    // MARK: - Content Helpers

    private mutating func addLabelContent(
        _ content: LabelContent,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double,
        rotateContent: Double
    ) {
        let totalRotation = rotation + rotateContent

        switch content {
        case .text(let text):
            addTextElement(text, at: point, fontSize: fontSize, foreground: foreground, rotation: totalRotation)

        case .sfSymbol(let name):
            addSFSymbolElement(name, at: point, fontSize: fontSize, foreground: foreground, rotation: totalRotation)

        case .image(let url):
            addImageElement(url, at: point, size: fontSize, rotation: totalRotation)
        }
    }

    private mutating func addTextElement(
        _ text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double
    ) {
        let transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        } else {
            transform = nil
        }

        document.addElement(XMLElement.text(
            text,
            x: point.x,
            y: point.y,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: "bold",
            fill: foreground,
            textAnchor: "middle",
            dominantBaseline: "central",
            transform: transform
        ))
    }

    private mutating func addSFSymbolElement(
        _ name: String,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double
    ) {
        // SF Symbols must be rasterized and embedded as base64 images
        // since SVG doesn't support SF Symbols natively
        guard let imageData = rasterizeSFSymbol(name: name, fontSize: fontSize, color: foreground) else {
            // Fallback: render the symbol name as text
            addTextElement("[\(name)]", at: point, fontSize: fontSize * 0.3, foreground: foreground, rotation: rotation)
            return
        }

        let imageSize = sfSymbolSize(name: name, fontSize: fontSize)
        let x = point.x - imageSize.width / 2
        let y = point.y - imageSize.height / 2

        var transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        }

        document.addImage(
            data: imageData,
            mimeType: "image/png",
            x: x,
            y: y,
            width: imageSize.width,
            height: imageSize.height,
            transform: transform
        )
    }

    private mutating func addImageElement(
        _ url: URL,
        at point: CGPoint,
        size contentSize: CGFloat,
        rotation: Double
    ) {
        guard let nsImage = NSImage(contentsOf: url),
              let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        // Calculate size maintaining aspect ratio
        let imageSize = nsImage.size
        let scale = min(contentSize / imageSize.width, contentSize / imageSize.height)
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let x = point.x - scaledWidth / 2
        let y = point.y - scaledHeight / 2

        var transform: String?
        if rotation != 0 {
            transform = SVGTransform.rotate(rotation, around: point)
        }

        document.addImage(
            data: pngData,
            mimeType: "image/png",
            x: x,
            y: y,
            width: scaledWidth,
            height: scaledHeight,
            transform: transform
        )
    }

    // MARK: - SF Symbol Rasterization

    private func rasterizeSFSymbol(name: String, fontSize: CGFloat, color: String) -> Data? {
        // Parse color from SVG string
        let nsColor = parseColor(color) ?? .black

        // Create SF Symbol image with configuration
        let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .bold)
        guard let symbolImage = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            return nil
        }

        // Tint the image
        let tintedImage = NSImage(size: symbolImage.size, flipped: false) { rect in
            symbolImage.draw(in: rect)
            nsColor.set()
            rect.fill(using: .sourceAtop)
            return true
        }

        // Convert to PNG
        guard let tiffData = tintedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        return pngData
    }

    private func sfSymbolSize(name: String, fontSize: CGFloat) -> CGSize {
        let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .bold)
        guard let symbolImage = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            return CGSize(width: fontSize, height: fontSize)
        }
        return symbolImage.size
    }

    private func parseColor(_ svgColor: String) -> NSColor? {
        if svgColor.hasPrefix("#") {
            // Parse hex color
            var hex = String(svgColor.dropFirst())
            if hex.count == 3 {
                hex = hex.map { "\($0)\($0)" }.joined()
            }
            guard hex.count == 6,
                  let value = UInt64(hex, radix: 16) else {
                return nil
            }
            let r = CGFloat((value >> 16) & 0xFF) / 255.0
            let g = CGFloat((value >> 8) & 0xFF) / 255.0
            let b = CGFloat(value & 0xFF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        } else if svgColor.hasPrefix("rgba(") {
            // Parse rgba color
            let inner = svgColor.dropFirst(5).dropLast()
            let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 4,
                  let r = Double(parts[0]),
                  let g = Double(parts[1]),
                  let b = Double(parts[2]),
                  let a = Double(parts[3]) else {
                return nil
            }
            return NSColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
        }
        return nil
    }

    // MARK: - Size Estimation

    private func estimateContentSize(_ content: LabelContent, fontSize: CGFloat) -> CGSize {
        switch content {
        case .text(let text):
            // Approximate text width based on character count
            let charWidth = fontSize * 0.6
            return CGSize(width: CGFloat(text.count) * charWidth, height: fontSize)

        case .sfSymbol(let name):
            return sfSymbolSize(name: name, fontSize: fontSize)

        case .image:
            // Use font size as approximate image dimension
            return CGSize(width: fontSize, height: fontSize)
        }
    }

    // MARK: - Output

    /// Get the rendered SVG as a string
    public func render(compact: Bool = false) -> String {
        document.render(compact: compact)
    }

    /// Get the rendered SVG as Data (UTF-8 encoded)
    public func renderData() -> Data? {
        render().data(using: .utf8)
    }
}
