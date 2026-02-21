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

    // MARK: - Gradient Tests

    @Test("Golden: Linear gradient")
    @MainActor
    func linearGradient() throws {
        let image = try renderIcon(
            background: Background("linear-gradient(to bottom, #FF6600, #CC0066)")
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "linear-gradient")
        #expect(matches, "Linear gradient should match golden image")
    }

    @Test("Golden: Radial gradient")
    @MainActor
    func radialGradient() throws {
        let image = try renderIcon(
            background: Background("radial-gradient(#FFCC00, #FF6600)")
        )

        let matches = try exactComparison.image(image: image, matchesGoldenImageNamed: "radial-gradient")
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
}

enum GoldenImageTestError: Error {
    case renderFailed
}
