import SwiftUI

// MARK: - IconRenderer Protocol

/// A protocol for rendering icons to different output formats (PNG, SVG, etc.)
///
/// The renderer receives high-level icon drawing commands and translates them
/// to the appropriate output format. This abstraction allows the same icon
/// configuration to be rendered to multiple formats.
///
/// ## Rendering Order
/// The typical rendering sequence is:
/// 1. `renderBackground()` - Fill the icon shape with background color/gradient
/// 2. `renderCenterContent()` - Draw center content (before clipping)
/// 3. `pushClip()` - Set up clipping to the icon shape
/// 4. `renderLabel()` (repeated) - Draw each label
/// 5. `popClip()` - Remove clipping
///
protocol IconRenderer {
    /// The size of the icon being rendered
    var size: CGSize { get }

    // MARK: - Background

    /// Render the icon background with the specified fill and corner style
    /// - Parameters:
    ///   - background: The background fill (solid color or gradient)
    ///   - cornerStyle: The corner style (none, rounded, squircle)
    ///   - cornerRadius: The corner radius as a ratio of icon size (0.0-0.5)
    mutating func renderBackground(
        _ background: Background,
        cornerStyle: CornerStyle,
        cornerRadius: CGFloat
    )

    // MARK: - Clipping

    /// Push a clip path matching the icon shape onto the clip stack
    /// All subsequent drawing will be clipped to this shape until `popClip()` is called.
    /// - Parameters:
    ///   - cornerStyle: The corner style for the clip path
    ///   - cornerRadius: The corner radius as a ratio of icon size
    mutating func pushClip(cornerStyle: CornerStyle, cornerRadius: CGFloat)

    /// Pop the most recent clip path from the clip stack
    mutating func popClip()

    // MARK: - Labels

    /// Render a label at the specified position
    /// The renderer determines the exact geometry based on the label position.
    /// - Parameter label: The label to render
    mutating func renderLabel(_ label: IconLabel)

    // MARK: - Center Content

    /// Render the center content of the icon
    /// - Parameter content: The content to render (text, SF Symbol, or image)
    mutating func renderCenterContent(_ content: CenterContent)
}

// MARK: - Render Pipeline

/// Render an icon using the provided renderer
///
/// This function orchestrates the rendering of an icon by calling the appropriate
/// renderer methods in the correct order.
///
/// - Parameters:
///   - renderer: The renderer to use
///   - background: The background fill
///   - cornerStyle: The corner style
///   - cornerRadius: The corner radius ratio
///   - labels: The labels to render
///   - centerContent: Optional center content
func renderIcon<R: IconRenderer>(
    to renderer: inout R,
    background: Background,
    cornerStyle: CornerStyle,
    cornerRadius: CGFloat,
    labels: [IconLabel],
    centerContent: CenterContent?
) {
    // 1. Render background
    renderer.renderBackground(background, cornerStyle: cornerStyle, cornerRadius: cornerRadius)

    // 2. Render center content (before clipping so it's not affected by label clip)
    if let center = centerContent {
        renderer.renderCenterContent(center)
    }

    // 3. Push clip for labels
    renderer.pushClip(cornerStyle: cornerStyle, cornerRadius: cornerRadius)

    // 4. Render each label
    for label in labels {
        renderer.renderLabel(label)
    }

    // 5. Pop clip
    renderer.popClip()
}

// MARK: - Geometry Helpers

/// Shared geometry calculations for icon rendering
enum IconGeometry {
    /// Standard ribbon thickness as a ratio of icon size
    static let ribbonThicknessRatio: CGFloat = 0.15

    /// Standard pill height as a ratio of icon size
    static let pillHeightRatio: CGFloat = 0.12

    /// Standard pill padding as a ratio of icon size
    static let pillPaddingRatio: CGFloat = 0.05

    /// Diagonal ribbon width as a ratio of icon size
    static let diagonalWidthRatio: CGFloat = 0.35

    /// Label font size as a ratio of icon size
    static let labelFontSizeRatio: CGFloat = 0.08

    /// Create the squircle/rounded rect path for the icon shape
    static func iconPath(in rect: CGRect, cornerStyle: CornerStyle, cornerRadius: CGFloat) -> Path {
        let radius = min(rect.width, rect.height) * cornerRadius
        if let style = cornerStyle.roundedCornerStyle {
            return Path(roundedRect: rect, cornerRadius: radius, style: style)
        } else {
            return Path(rect)
        }
    }

    /// Calculate the rect for an edge ribbon
    static func edgeRibbonRect(for position: LabelPosition, in size: CGSize) -> CGRect {
        let thickness = size.height * ribbonThicknessRatio
        switch position {
        case .top:
            return CGRect(x: 0, y: 0, width: size.width, height: thickness)
        case .bottom:
            return CGRect(x: 0, y: size.height - thickness, width: size.width, height: thickness)
        case .left:
            return CGRect(x: 0, y: 0, width: thickness, height: size.height)
        case .right:
            return CGRect(x: size.width - thickness, y: 0, width: thickness, height: size.height)
        default:
            return .zero
        }
    }

    /// Calculate the triangle path for a corner ribbon
    static func cornerRibbonPath(for position: LabelPosition, in size: CGSize) -> Path {
        let width = size.width * diagonalWidthRatio
        var path = Path()

        switch position {
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
        default:
            break
        }

        return path
    }

    /// Calculate the centroid point for a corner ribbon (where content is placed)
    static func cornerRibbonCentroid(for position: LabelPosition, in size: CGSize) -> CGPoint {
        let width = size.width * diagonalWidthRatio
        switch position {
        case .topLeft:
            return CGPoint(x: width / 3, y: width / 3)
        case .topRight:
            return CGPoint(x: size.width - width / 3, y: width / 3)
        case .bottomLeft:
            return CGPoint(x: width / 3, y: size.height - width / 3)
        case .bottomRight:
            return CGPoint(x: size.width - width / 3, y: size.height - width / 3)
        default:
            return .zero
        }
    }

    /// Get the rotation angle for a corner ribbon's content
    static func cornerRibbonRotation(for position: LabelPosition) -> Angle {
        switch position {
        case .topLeft: return .degrees(-45)
        case .topRight: return .degrees(45)
        case .bottomLeft: return .degrees(45)
        case .bottomRight: return .degrees(-45)
        default: return .zero
        }
    }

    /// Calculate pill rect for a given position and content size
    /// - Parameters:
    ///   - position: The pill position (pillLeft, pillCenter, pillRight)
    ///   - size: The icon size
    ///   - contentSize: The size of the content inside the pill
    ///   - cornerRadiusRatio: The icon's corner radius ratio (for safe padding)
    static func pillRect(
        for position: LabelPosition,
        in size: CGSize,
        contentSize: CGSize,
        cornerRadiusRatio: CGFloat
    ) -> CGRect {
        let pillHeight = size.height * pillHeightRatio
        let pillPadding = size.width * pillPaddingRatio
        let cornerSafePadding = size.width * (cornerRadiusRatio * 0.6 + 0.02)
        let pillWidth = contentSize.width + pillPadding * 2

        let y = size.height - pillHeight - pillPadding

        switch position {
        case .pillLeft:
            return CGRect(x: cornerSafePadding, y: y, width: pillWidth, height: pillHeight)
        case .pillCenter:
            return CGRect(x: (size.width - pillWidth) / 2, y: y, width: pillWidth, height: pillHeight)
        case .pillRight:
            return CGRect(x: size.width - pillWidth - cornerSafePadding, y: y, width: pillWidth, height: pillHeight)
        default:
            return .zero
        }
    }

    /// Get the font size for labels
    static func labelFontSize(for iconSize: CGSize) -> CGFloat {
        iconSize.width * labelFontSizeRatio
    }
}
