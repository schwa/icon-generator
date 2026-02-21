import Testing
import Foundation
import AppKit
import IconRendering
import SVGXML
import SVGRasterizer
import GoldenImage

@testable import icon_generator

/// Golden SVG tests - compares SVG output both textually and visually (via WebKit rasterization)
@Suite("SVG Golden Tests")
struct SVGGoldenTests {

    private var goldenSVGsURL: URL {
        Bundle.module.resourceURL!.appendingPathComponent("GoldenSVGs")
    }

    // MARK: - Comparisons

    /// Text comparison with normalized XML
    private var textComparison: GoldenImageComparison {
        GoldenImageComparison(
            imageDirectory: goldenSVGsURL,
            options: .none,
            psnrThreshold: 120.0
        )
    }

    /// Visual comparison for rasterized SVG (allow minor WebKit rendering variations)
    private var visualComparison: GoldenImageComparison {
        GoldenImageComparison(
            imageDirectory: goldenSVGsURL.deletingLastPathComponent().appendingPathComponent("GoldenSVGRasters"),
            options: .none,
            psnrThreshold: 35.0  // WebKit rendering may have minor differences
        )
    }

    // MARK: - XML Normalization

    private func normalizeXML(_ xml: String) -> String {
        var normalized = xml
            .replacingOccurrences(of: #"<\?xml[^?]*\?>\n?"#, with: "", options: .regularExpression)
        normalized = normalized
            .replacingOccurrences(of: #">\s+<"#, with: "><", options: .regularExpression)
        normalized = normalized.replacingOccurrences(
            of: #"="(\d+\.\d{3,})""#,
            with: { match in
                guard let range = match.range(of: #"\d+\.\d+"#, options: .regularExpression),
                      let value = Double(match[range]) else {
                    return String(match)
                }
                let rounded = (value * 100).rounded() / 100
                return "=\"\(rounded)\""
            }
        )
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helper Methods

    @MainActor
    private func renderSVG(
        background: Background = .solid(CSSColor("#3366FF")),
        size: Int = 256,
        cornerStyle: CornerStyle = .squircle,
        cornerRadiusRatio: Double = 0.2237,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) throws -> String {
        var renderer = SVGIconRenderer(
            size: CGSize(width: size, height: size),
            cornerRadiusRatio: cornerRadiusRatio
        )

        renderer.renderBackground(background, cornerStyle: cornerStyle, cornerRadius: cornerRadiusRatio)

        if !labels.isEmpty || centerContent != nil {
            renderer.pushClip(cornerStyle: cornerStyle, cornerRadius: cornerRadiusRatio)
        }

        for label in labels {
            renderer.renderLabel(label)
        }

        if let center = centerContent {
            renderer.renderCenterContent(center)
        }

        return renderer.render(compact: true)
    }

    private func loadGoldenSVG(named name: String) throws -> String? {
        let url = goldenSVGsURL.appendingPathComponent("\(name).svg")
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func saveGoldenSVG(_ svg: String, named name: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("GoldenSVGs")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let url = tempDir.appendingPathComponent("\(name).svg")
        try svg.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func compareSVGText(_ generated: String, toGoldenNamed name: String) throws -> Bool {
        if let golden = try loadGoldenSVG(named: name) {
            let normalizedGenerated = normalizeXML(generated)
            let normalizedGolden = normalizeXML(golden)
            return normalizedGenerated == normalizedGolden
        } else {
            let url = try saveGoldenSVG(generated, named: name)
            throw SVGGoldenTestError.noGoldenSVG(savedTo: url)
        }
    }

    @MainActor
    private func compareSVGVisual(_ svg: String, toGoldenNamed name: String, size: CGSize) async throws -> Bool {
        let rasterizer = SVGRasterizer()
        let rasterized = try await rasterizer.rasterize(svg: svg, size: size)

        // Check if golden raster exists
        let goldenRastersURL = goldenSVGsURL.deletingLastPathComponent().appendingPathComponent("GoldenSVGRasters")
        let goldenURL = goldenRastersURL.appendingPathComponent("\(name).png")

        if FileManager.default.fileExists(atPath: goldenURL.path) {
            return try visualComparison.image(image: rasterized, matchesGoldenImageNamed: name)
        } else {
            // Save rasterized image as new golden
            try FileManager.default.createDirectory(at: goldenRastersURL, withIntermediateDirectories: true)
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("GoldenSVGRasters")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let tempURL = tempDir.appendingPathComponent("\(name).png")

            let rep = NSBitmapImageRep(cgImage: rasterized)
            guard let data = rep.representation(using: .png, properties: [:]) else {
                throw SVGGoldenTestError.rasterizationFailed
            }
            try data.write(to: tempURL)

            throw SVGGoldenTestError.noGoldenRaster(savedTo: tempURL)
        }
    }

    // MARK: - Basic Shape Tests

    @Test("SVG Golden: Basic squircle")
    @MainActor
    func basicSquircle() async throws {
        let svg = try renderSVG(
            background: .solid(CSSColor("#3366FF")),
            cornerStyle: .squircle
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "basic-squircle")
        #expect(textMatches, "Basic squircle SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "basic-squircle", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Basic squircle SVG visual should match golden")
    }

    @Test("SVG Golden: Rounded corners")
    @MainActor
    func roundedCorners() async throws {
        let svg = try renderSVG(
            background: .solid(CSSColor("#FF6600")),
            cornerStyle: .rounded
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "rounded-corners")
        #expect(textMatches, "Rounded corners SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "rounded-corners", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Rounded corners SVG visual should match golden")
    }

    @Test("SVG Golden: Square corners")
    @MainActor
    func squareCorners() async throws {
        let svg = try renderSVG(
            background: .solid(CSSColor("#00CC66")),
            cornerStyle: .none
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "square-corners")
        #expect(textMatches, "Square corners SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "square-corners", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Square corners SVG visual should match golden")
    }

    // MARK: - Gradient Tests

    @Test("SVG Golden: Linear gradient")
    @MainActor
    func linearGradient() async throws {
        let svg = try renderSVG(
            background: Background("linear-gradient(to bottom, #FF6600, #CC0066)")
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "linear-gradient")
        #expect(textMatches, "Linear gradient SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "linear-gradient", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Linear gradient SVG visual should match golden")
    }

    @Test("SVG Golden: Radial gradient")
    @MainActor
    func radialGradient() async throws {
        let svg = try renderSVG(
            background: Background("radial-gradient(#FFCC00, #FF6600)")
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "radial-gradient")
        #expect(textMatches, "Radial gradient SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "radial-gradient", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Radial gradient SVG visual should match golden")
    }

    @Test("SVG Golden: Angular gradient")
    @MainActor
    func angularGradient() async throws {
        let svg = try renderSVG(
            background: Background("angular-gradient(#FF0000, #00FF00, #0000FF, #FF0000)")
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "angular-gradient")
        #expect(textMatches, "Angular gradient SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "angular-gradient", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Angular gradient SVG visual should match golden")
    }

    // MARK: - Label Tests

    @Test("SVG Golden: Corner ribbon")
    @MainActor
    func cornerRibbon() async throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "corner-ribbon")
        #expect(textMatches, "Corner ribbon SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "corner-ribbon", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Corner ribbon SVG visual should match golden")
    }

    @Test("SVG Golden: Edge ribbon")
    @MainActor
    func edgeRibbon() async throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("TOP"), position: .top, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "edge-ribbon")
        #expect(textMatches, "Edge ribbon SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "edge-ribbon", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Edge ribbon SVG visual should match golden")
    }

    @Test("SVG Golden: Pill label")
    @MainActor
    func pillLabel() async throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000"))
            ]
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "pill-label")
        #expect(textMatches, "Pill label SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "pill-label", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Pill label SVG visual should match golden")
    }

    @Test("SVG Golden: All label positions")
    @MainActor
    func allLabelPositions() async throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("TL"), position: .topLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("TR"), position: .topRight, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
                IconLabel(content: .text("T"), position: .top, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("P"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            ]
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "all-label-positions")
        #expect(textMatches, "All label positions SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "all-label-positions", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "All label positions SVG visual should match golden")
    }

    // MARK: - Center Content Tests

    @Test("SVG Golden: Center text")
    @MainActor
    func centerText() async throws {
        let svg = try renderSVG(
            centerContent: CenterContent(content: .text("A"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "center-text")
        #expect(textMatches, "Center text SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "center-text", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Center text SVG visual should match golden")
    }

    @Test("SVG Golden: Center SF Symbol")
    @MainActor
    func centerSFSymbol() async throws {
        let svg = try renderSVG(
            centerContent: CenterContent(content: .sfSymbol("swift"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "center-sf-symbol")
        #expect(textMatches, "Center SF Symbol SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "center-sf-symbol", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Center SF Symbol SVG visual should match golden")
    }

    @Test("SVG Golden: Center rotated")
    @MainActor
    func centerRotated() async throws {
        let svg = try renderSVG(
            centerContent: CenterContent(content: .sfSymbol("arrow.up"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, rotation: 45)
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "center-rotated")
        #expect(textMatches, "Center rotated SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "center-rotated", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Center rotated SVG visual should match golden")
    }

    // MARK: - Complex Tests

    @Test("SVG Golden: Kitchen sink")
    @MainActor
    func kitchenSink() async throws {
        let svg = try renderSVG(
            background: Background("linear-gradient(135deg, #667eea, #764ba2)"),
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            ],
            centerContent: CenterContent(content: .text("S"), color: CSSColor("#FFFFFF"), sizeRatio: 0.4)
        )

        let textMatches = try compareSVGText(svg, toGoldenNamed: "kitchen-sink")
        #expect(textMatches, "Kitchen sink SVG text should match golden")

        let visualMatches = try await compareSVGVisual(svg, toGoldenNamed: "kitchen-sink", size: CGSize(width: 256, height: 256))
        #expect(visualMatches, "Kitchen sink SVG visual should match golden")
    }
}

enum SVGGoldenTestError: Error {
    case noGoldenSVG(savedTo: URL)
    case noGoldenRaster(savedTo: URL)
    case rasterizationFailed
}

// Extension to support regex replacement with closure
extension String {
    func replacingOccurrences(of pattern: String, with replacement: (Substring) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        let range = NSRange(startIndex..., in: self)
        var result = self
        let matches = regex.matches(in: self, range: range).reversed()
        for match in matches {
            guard let swiftRange = Range(match.range, in: self) else { continue }
            let replacement = replacement(self[swiftRange])
            result.replaceSubrange(swiftRange, with: replacement)
        }
        return result
    }
}
