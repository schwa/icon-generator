import Testing
import Foundation
import AppKit
import SwiftUI
import IconRendering
import SVGRasterizer
import GoldenImage

/// Compare PNG renderer output to SVG renderer output (via WebKit rasterization)
@Suite("Renderer Comparison Tests")
struct RendererComparisonTests {

    /// Compare basic squircle - no content, just background shape
    @Test("PNG vs SVG: Basic squircle")
    @MainActor
    func basicSquircle() async throws {
        let size = 256
        let background = Background.solid(CSSColor("#3366FF"))
        let cornerStyle = CornerStyle.squircle
        let cornerRadiusRatio = 0.2237

        // Render via PNG (SquircleView + ImageRenderer)
        let pngImage = try renderPNG(
            background: background,
            size: size,
            cornerStyle: cornerStyle,
            cornerRadiusRatio: cornerRadiusRatio
        )

        // Render via SVG (SVGIconRenderer + WebKit)
        let svgImage = try await renderSVG(
            background: background,
            size: size,
            cornerStyle: cornerStyle,
            cornerRadiusRatio: cornerRadiusRatio
        )



        // Normalize color spaces for comparison
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let normalizedPNG = pngImage.copy(colorSpace: colorSpace),
              let normalizedSVG = svgImage.copy(colorSpace: colorSpace) else {
            throw RendererComparisonError.pngRenderFailed
        }

        // Compare - allow some tolerance for rendering differences
        let comparison = try ImageComparison()
        let result = try comparison.compare(normalizedPNG, normalizedSVG)

        // PSNR > 30 dB is considered "good" quality match
        #expect(result.psnr >= 30.0, "PNG and SVG renderers should produce similar output (PSNR: \(result.psnr) dB)")
    }

    // MARK: - Helpers

    @MainActor
    private func renderPNG(
        background: Background,
        size: Int,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double
    ) throws -> CGImage {
        let view = SquircleView(
            background: background,
            size: CGFloat(size),
            cornerStyle: cornerStyle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: [],
            centerContent: nil
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else {
            throw RendererComparisonError.pngRenderFailed
        }

        return cgImage
    }

    @MainActor
    private func renderSVG(
        background: Background,
        size: Int,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double
    ) async throws -> CGImage {
        var renderer = SVGIconRenderer(
            size: CGSize(width: size, height: size),
            cornerRadiusRatio: cornerRadiusRatio
        )

        renderer.renderBackground(background, cornerStyle: cornerStyle, cornerRadius: cornerRadiusRatio)

        let svg = renderer.render(compact: true)

        let rasterizer = SVGRasterizer()
        return try await rasterizer.rasterize(svg: svg, size: CGSize(width: size, height: size))
    }
}

enum RendererComparisonError: Error {
    case pngRenderFailed
    case svgRenderFailed
}
