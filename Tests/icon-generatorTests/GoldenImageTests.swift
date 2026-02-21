import Testing
import Foundation
import CoreGraphics
import ImageIO
import SwiftUI
import GoldenImage
import IconRendering
import UniformTypeIdentifiers

@testable import icon_generator

/// Golden image tests to prevent visual regressions in icon rendering
@Suite("Golden Image Tests")
struct GoldenImageTests {

    private var goldenImagesURL: URL {
        Bundle.module.resourceURL!.appendingPathComponent("GoldenImages")
    }

    /// Comparison for tests without text - requires exact match
    private var exactComparison: GoldenImageComparison {
        GoldenImageComparison(
            imageDirectory: goldenImagesURL,
            options: .none,
            psnrThreshold: 120.0
        )
    }

    /// Comparison for tests with text/fonts - allows minor variations
    /// 40 dB is "excellent" quality with barely noticeable differences
    private var textComparison: GoldenImageComparison {
        GoldenImageComparison(
            imageDirectory: goldenImagesURL,
            options: .none,
            psnrThreshold: 40.0
        )
    }

    // MARK: - Helper Methods

    @MainActor
    private func renderIcon(
        background: Background = .solid(CSSColor("#3366FF")),
        size: Int = 256,
        cornerStyle: CornerStyle = .squircle,
        cornerRadiusRatio: Double = 0.2237,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) throws -> CGImage {
        let view = SquircleView(
            background: background,
            size: CGFloat(size),
            cornerStyle: cornerStyle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: labels,
            centerContent: centerContent
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else {
            throw GoldenImageTestError.renderFailed
        }

        return cgImage
    }

    // MARK: - Basic Shape Tests

    @Test("Golden: Basic squircle")
    @MainActor
    func basicSquircle() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("#3366FF")),
            cornerStyle: .squircle
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "basic-squircle")
        #expect(matches, "Basic squircle should match golden image")
    }

    @Test("Golden: Rounded corners")
    @MainActor
    func roundedCorners() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("#FF6600")),
            cornerStyle: .rounded
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "rounded-corners")
        #expect(matches, "Rounded corners should match golden image")
    }

    @Test("Golden: Square corners")
    @MainActor
    func squareCorners() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("#00CC66")),
            cornerStyle: .none
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "square-corners")
        #expect(matches, "Square corners should match golden image")
    }

    // MARK: - Gradient Tests (use textComparison due to potential floating-point variations)

    @Test("Golden: Linear gradient")
    @MainActor
    func linearGradient() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(to bottom, #FF6600, #CC0066)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "linear-gradient")
        #expect(matches, "Linear gradient should match golden image")
    }

    @Test("Golden: Radial gradient")
    @MainActor
    func radialGradient() throws {
        let image = try renderIcon(
            background: Background("radial-gradient(#FFCC00, #FF6600)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "radial-gradient")
        #expect(matches, "Radial gradient should match golden image")
    }

    // MARK: - Label Tests (use textComparison due to font rendering variations)

    @Test("Golden: Corner ribbon")
    @MainActor
    func cornerRibbon() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "corner-ribbon")
        #expect(matches, "Corner ribbon should match golden image")
    }

    @Test("Golden: Edge ribbon")
    @MainActor
    func edgeRibbon() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("TOP"), position: .top, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "edge-ribbon")
        #expect(matches, "Edge ribbon should match golden image")
    }

    @Test("Golden: Pill label")
    @MainActor
    func pillLabel() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "pill-label")
        #expect(matches, "Pill label should match golden image")
    }

    // MARK: - Center Content Tests (use textComparison due to font/symbol rendering variations)

    @Test("Golden: Center text")
    @MainActor
    func centerText() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("A"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-text")
        #expect(matches, "Center text should match golden image")
    }

    @Test("Golden: Center SF Symbol")
    @MainActor
    func centerSFSymbol() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .sfSymbol("swift"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-sf-symbol")
        #expect(matches, "Center SF Symbol should match golden image")
    }

    // MARK: - Angular Gradient Tests (use textComparison due to potential floating-point variations)

    @Test("Golden: Angular gradient")
    @MainActor
    func angularGradient() throws {
        let image = try renderIcon(
            background: Background("angular-gradient(#FF0000, #FF7F00, #FFFF00, #00FF00, #0000FF, #8B00FF, #FF0000)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "angular-gradient")
        #expect(matches, "Angular gradient should match golden image")
    }

    @Test("Golden: Linear gradient diagonal")
    @MainActor
    func linearGradientDiagonal() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(45deg, #FF6600, #CC0066)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "linear-gradient-diagonal")
        #expect(matches, "Diagonal linear gradient should match golden image")
    }

    // MARK: - Corner Radius Tests

    @Test("Golden: Large corner radius")
    @MainActor
    func largeCornerRadius() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("#9933FF")),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.4
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "large-corner-radius")
        #expect(matches, "Large corner radius should match golden image")
    }

    @Test("Golden: Small corner radius")
    @MainActor
    func smallCornerRadius() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("#33CC99")),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.1
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "small-corner-radius")
        #expect(matches, "Small corner radius should match golden image")
    }

    // MARK: - All Label Position Tests

    @Test("Golden: All corner ribbons")
    @MainActor
    func allCornerRibbons() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("TL"), position: .topLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("TR"), position: .topRight, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
                IconLabel(content: .text("BL"), position: .bottomLeft, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("BR"), position: .bottomRight, backgroundColor: CSSColor("#FFFF00"), foregroundColor: CSSColor("#000000")),
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "all-corner-ribbons")
        #expect(matches, "All corner ribbons should match golden image")
    }

    @Test("Golden: All edge ribbons")
    @MainActor
    func allEdgeRibbons() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("TOP"), position: .top, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("BOT"), position: .bottom, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
                IconLabel(content: .text("L"), position: .left, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("R"), position: .right, backgroundColor: CSSColor("#FFFF00"), foregroundColor: CSSColor("#000000")),
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "all-edge-ribbons")
        #expect(matches, "All edge ribbons should match golden image")
    }

    @Test("Golden: All pill positions")
    @MainActor
    func allPillPositions() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("L"), position: .pillLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("C"), position: .pillCenter, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
                IconLabel(content: .text("R"), position: .pillRight, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "all-pill-positions")
        #expect(matches, "All pill positions should match golden image")
    }

    // MARK: - SF Symbol in Labels

    @Test("Golden: SF Symbol corner ribbon")
    @MainActor
    func sfSymbolCornerRibbon() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .sfSymbol("star.fill"), position: .topRight, backgroundColor: CSSColor("#FFD700"), foregroundColor: CSSColor("#000000"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "sf-symbol-corner-ribbon")
        #expect(matches, "SF Symbol corner ribbon should match golden image")
    }

    @Test("Golden: SF Symbol pill")
    @MainActor
    func sfSymbolPill() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .sfSymbol("heart.fill"), position: .pillCenter, backgroundColor: CSSColor("#FF69B4"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "sf-symbol-pill")
        #expect(matches, "SF Symbol pill should match golden image")
    }

    // MARK: - Center Content Variations

    @Test("Golden: Center large size")
    @MainActor
    func centerLargeSize() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("X"), color: CSSColor("#FFFFFF"), sizeRatio: 0.8)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-large-size")
        #expect(matches, "Center large size should match golden image")
    }

    @Test("Golden: Center small size")
    @MainActor
    func centerSmallSize() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("tiny"), color: CSSColor("#FFFFFF"), sizeRatio: 0.2)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-small-size")
        #expect(matches, "Center small size should match golden image")
    }

    @Test("Golden: Center with y-offset")
    @MainActor
    func centerWithYOffset() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("↑"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, yOffset: 0.15)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-y-offset")
        #expect(matches, "Center with y-offset should match golden image")
    }

    @Test("Golden: Center rotated")
    @MainActor
    func centerRotated() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .sfSymbol("arrow.up"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, rotation: 45)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-rotated")
        #expect(matches, "Center rotated should match golden image")
    }

    // MARK: - Color Tests

    @Test("Golden: Transparent background")
    @MainActor
    func transparentBackground() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("rgba(51, 102, 255, 0.5)")),
            centerContent: CenterContent(content: .text("α"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "transparent-background")
        #expect(matches, "Transparent background should match golden image")
    }

    @Test("Golden: Named colors")
    @MainActor
    func namedColors() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("coral")),
            labels: [
                IconLabel(content: .text("OK"), position: .pillCenter, backgroundColor: CSSColor("navy"), foregroundColor: CSSColor("white"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "named-colors")
        #expect(matches, "Named colors should match golden image")
    }

    // MARK: - Complex Tests (use textComparison due to text content)

    @Test("Golden: Kitchen sink")
    @MainActor
    func kitchenSink() throws {
        let labels = [
            IconLabel(content: .sfSymbol("star.fill"), position: .topLeft, backgroundColor: CSSColor("#FFD700"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
        ]

        let image = try renderIcon(
            background: Background("linear-gradient(135deg, #667eea, #764ba2)"),
            labels: labels,
            centerContent: CenterContent(content: .sfSymbol("swift"), color: CSSColor("#FFFFFF"), sizeRatio: 0.4)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "kitchen-sink")
        #expect(matches, "Kitchen sink should match golden image")
    }

    @Test("Golden: Maximum labels")
    @MainActor
    func maximumLabels() throws {
        // Test with all possible label positions filled
        let labels = [
            // Corner ribbons
            IconLabel(content: .text("1"), position: .topLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("2"), position: .topRight, backgroundColor: CSSColor("#FF7F00"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("3"), position: .bottomLeft, backgroundColor: CSSColor("#FFFF00"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("4"), position: .bottomRight, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
            // Edge ribbons
            IconLabel(content: .text("T"), position: .top, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("B"), position: .bottom, backgroundColor: CSSColor("#4B0082"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("L"), position: .left, backgroundColor: CSSColor("#8B00FF"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("R"), position: .right, backgroundColor: CSSColor("#FF1493"), foregroundColor: CSSColor("#FFFFFF")),
            // Pills
            IconLabel(content: .text("PL"), position: .pillLeft, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("PC"), position: .pillCenter, backgroundColor: CSSColor("#CCCCCC"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("PR"), position: .pillRight, backgroundColor: CSSColor("#999999"), foregroundColor: CSSColor("#FFFFFF")),
        ]

        let image = try renderIcon(
            background: .solid(CSSColor("#333333")),
            labels: labels
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "maximum-labels")
        #expect(matches, "Maximum labels should match golden image")
    }

    @Test("Golden: Gradient with center and labels")
    @MainActor
    func gradientWithCenterAndLabels() throws {
        let image = try renderIcon(
            background: Background("radial-gradient(#4158D0, #C850C0, #FFCC70)"),
            labels: [
                IconLabel(content: .text("PRO"), position: .topRight, backgroundColor: CSSColor("#FFD700"), foregroundColor: CSSColor("#000000")),
                IconLabel(content: .text("v3.0"), position: .pillRight, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            ],
            centerContent: CenterContent(content: .sfSymbol("sparkles"), color: CSSColor("#FFFFFF"), sizeRatio: 0.45)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "gradient-center-labels")
        #expect(matches, "Gradient with center and labels should match golden image")
    }

    // MARK: - Label norotate Tests

    @Test("Golden: Corner ribbon norotate")
    @MainActor
    func cornerRibbonNorotate() throws {
        // With rotateContent=false, text stays upright on diagonal ribbons
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("UP"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"), rotateContent: false)
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "corner-ribbon-norotate")
        #expect(matches, "Corner ribbon norotate should match golden image")
    }

    @Test("Golden: Corner ribbon rotated vs norotate comparison")
    @MainActor
    func cornerRibbonRotateComparison() throws {
        // Show both rotated (default) and non-rotated on same icon
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("ROT"), position: .topLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"), rotateContent: true),
                IconLabel(content: .text("UP"), position: .topRight, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF"), rotateContent: false),
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "corner-ribbon-rotate-comparison")
        #expect(matches, "Corner ribbon rotate comparison should match golden image")
    }

    // MARK: - Center Alignment Tests

    @Test("Golden: Center visual alignment")
    @MainActor
    func centerVisualAlignment() throws {
        // Visual alignment centers based on glyph bounding box - good for asymmetric characters
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("Ə"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, alignment: .visual)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-visual-alignment")
        #expect(matches, "Center visual alignment should match golden image")
    }

    @Test("Golden: Center typographic alignment")
    @MainActor
    func centerTypographicAlignment() throws {
        // Typographic alignment (default) - uses font metrics
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("Ə"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, alignment: .typographic)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-typographic-alignment")
        #expect(matches, "Center typographic alignment should match golden image")
    }

    // MARK: - Center Anchor Tests

    @Test("Golden: Center anchor baseline")
    @MainActor
    func centerAnchorBaseline() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("Ag"), color: CSSColor("#FFFFFF"), sizeRatio: 0.4, anchor: .baseline)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-anchor-baseline")
        #expect(matches, "Center anchor baseline should match golden image")
    }

    @Test("Golden: Center anchor cap")
    @MainActor
    func centerAnchorCap() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("Ag"), color: CSSColor("#FFFFFF"), sizeRatio: 0.4, anchor: .cap)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-anchor-cap")
        #expect(matches, "Center anchor cap should match golden image")
    }

    @Test("Golden: Center anchor center")
    @MainActor
    func centerAnchorCenter() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("Ag"), color: CSSColor("#FFFFFF"), sizeRatio: 0.4, anchor: .center)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-anchor-center")
        #expect(matches, "Center anchor center should match golden image")
    }

    // MARK: - Embedded Image Tests

    @Test("Golden: Embedded image in center")
    @MainActor
    func embeddedImageCenter() throws {
        // First generate a simple test image
        let testImageURL = try createTestImage()

        let image = try renderIcon(
            centerContent: CenterContent(content: .image(testImageURL), color: CSSColor("#FFFFFF"), sizeRatio: 0.4)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "embedded-image-center")
        #expect(matches, "Embedded image in center should match golden image")
    }

    @Test("Golden: Embedded image in pill label")
    @MainActor
    func embeddedImagePill() throws {
        let testImageURL = try createTestImage()

        let image = try renderIcon(
            labels: [
                IconLabel(content: .image(testImageURL), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "embedded-image-pill")
        #expect(matches, "Embedded image in pill should match golden image")
    }

    @Test("Golden: Embedded image in corner ribbon")
    @MainActor
    func embeddedImageCornerRibbon() throws {
        let testImageURL = try createTestImage()

        let image = try renderIcon(
            labels: [
                IconLabel(content: .image(testImageURL), position: .topRight, backgroundColor: CSSColor("#FFD700"), foregroundColor: CSSColor("#000000"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "embedded-image-corner")
        #expect(matches, "Embedded image in corner ribbon should match golden image")
    }

    // MARK: - Gradient Direction Tests

    @Test("Golden: Linear gradient to top")
    @MainActor
    func linearGradientToTop() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(to top, #FF6600, #CC0066)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "linear-gradient-to-top")
        #expect(matches, "Linear gradient to top should match golden image")
    }

    @Test("Golden: Linear gradient to right")
    @MainActor
    func linearGradientToRight() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(to right, #00FF00, #0000FF)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "linear-gradient-to-right")
        #expect(matches, "Linear gradient to right should match golden image")
    }

    @Test("Golden: Linear gradient to bottom right")
    @MainActor
    func linearGradientToBottomRight() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(to bottom right, #FFCC00, #FF00CC)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "linear-gradient-to-bottom-right")
        #expect(matches, "Linear gradient to bottom right should match golden image")
    }

    @Test("Golden: Multi-stop gradient")
    @MainActor
    func multiStopGradient() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(to bottom, #FF0000, #FFFF00, #00FF00, #00FFFF, #0000FF)")
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "multi-stop-gradient")
        #expect(matches, "Multi-stop gradient should match golden image")
    }

    // MARK: - Label Rotation Tests

    @Test("Golden: Label with rotation")
    @MainActor
    func labelWithRotation() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .sfSymbol("arrow.right"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000"), rotation: 45)
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "label-with-rotation")
        #expect(matches, "Label with rotation should match golden image")
    }

    // MARK: - Edge Cases

    @Test("Golden: Very long text in pill")
    @MainActor
    func veryLongTextInPill() throws {
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("LONGTEXT"), position: .pillCenter, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "very-long-text-pill")
        #expect(matches, "Very long text in pill should match golden image")
    }

    @Test("Golden: Multiple center rotations")
    @MainActor
    func multipleCenterRotations() throws {
        // Test various rotation angles
        let image = try renderIcon(
            centerContent: CenterContent(content: .sfSymbol("arrow.up"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, rotation: 90)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-rotation-90")
        #expect(matches, "Center rotation 90 should match golden image")
    }

    @Test("Golden: Center rotation 180")
    @MainActor
    func centerRotation180() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .sfSymbol("arrow.up"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, rotation: 180)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-rotation-180")
        #expect(matches, "Center rotation 180 should match golden image")
    }

    @Test("Golden: Negative y-offset")
    @MainActor
    func negativeYOffset() throws {
        let image = try renderIcon(
            centerContent: CenterContent(content: .text("↓"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, yOffset: -0.15)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "center-negative-y-offset")
        #expect(matches, "Negative y-offset should match golden image")
    }

    @Test("Golden: RGB color format")
    @MainActor
    func rgbColorFormat() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("rgb(128, 0, 255)"))
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "rgb-color-format")
        #expect(matches, "RGB color format should match golden image")
    }

    @Test("Golden: RGBA color format")
    @MainActor
    func rgbaColorFormat() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("rgba(255, 128, 0, 0.75)")),
            centerContent: CenterContent(content: .text("75%"), color: CSSColor("#000000"), sizeRatio: 0.3)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "rgba-color-format")
        #expect(matches, "RGBA color format should match golden image")
    }

    @Test("Golden: Short hex color")
    @MainActor
    func shortHexColor() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("#F0F"))  // Short form of #FF00FF
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "short-hex-color")
        #expect(matches, "Short hex color should match golden image")
    }

    @Test("Golden: Overlapping labels")
    @MainActor
    func overlappingLabels() throws {
        // Corner and edge labels that might overlap
        let image = try renderIcon(
            labels: [
                IconLabel(content: .text("CORNER"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("EDGE"), position: .top, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
            ]
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "overlapping-labels")
        #expect(matches, "Overlapping labels should match golden image")
    }

    @Test("Golden: Full alpha transparency")
    @MainActor
    func fullAlphaTransparency() throws {
        let image = try renderIcon(
            background: .solid(CSSColor("rgba(255, 0, 0, 0.0)")),  // Fully transparent
            centerContent: CenterContent(content: .text("?"), color: CSSColor("#000000"), sizeRatio: 0.5)
        )

        let matches = try textComparison.image(image: image, matchesGoldenImageNamed: "full-alpha-transparency")
        #expect(matches, "Full alpha transparency should match golden image")
    }

    // MARK: - Helper for Creating Test Image

    /// Creates a simple 64x64 test image (red circle on transparent background)
    @MainActor
    private func createTestImage() throws -> URL {
        let size = 64
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-icon-\(size).png")

        // Check if already exists (reuse for consistency)
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        // Create a simple red circle image
        let view = Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            context.fill(Ellipse().path(in: rect), with: .color(.red))
        }
        .frame(width: CGFloat(size), height: CGFloat(size))

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else {
            throw GoldenImageTestError.renderFailed
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw GoldenImageTestError.renderFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw GoldenImageTestError.renderFailed
        }

        return url
    }
}

enum GoldenImageTestError: Error {
    case renderFailed
}
