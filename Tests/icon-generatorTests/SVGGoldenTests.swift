import Testing
import Foundation
import IconRendering
import SVGXML

@testable import icon_generator

/// Golden SVG tests to prevent regressions in SVG output
@Suite("SVG Golden Tests")
struct SVGGoldenTests {

    private var goldenSVGsURL: URL {
        Bundle.module.resourceURL!.appendingPathComponent("GoldenSVGs")
    }

    // MARK: - XML Normalization

    /// Normalize XML for comparison by sorting attributes and standardizing whitespace
    private func normalizeXML(_ xml: String) -> String {
        // Remove XML declaration variations
        var normalized = xml
            .replacingOccurrences(of: #"<\?xml[^?]*\?>\n?"#, with: "", options: .regularExpression)

        // Normalize whitespace between tags
        normalized = normalized
            .replacingOccurrences(of: #">\s+<"#, with: "><", options: .regularExpression)

        // Normalize floating point precision (round to 2 decimal places in attributes)
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

        // Sort lines for consistent ordering (simple approach)
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

        // Note: cornerRadiusRatio is passed directly - IconGeometry.iconPath multiplies by size internally
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

    private func compareSVG(_ generated: String, toGoldenNamed name: String) throws -> Bool {
        if let golden = try loadGoldenSVG(named: name) {
            let normalizedGenerated = normalizeXML(generated)
            let normalizedGolden = normalizeXML(golden)
            return normalizedGenerated == normalizedGolden
        } else {
            // No golden file - save to temp for copying
            let url = try saveGoldenSVG(generated, named: name)
            throw SVGGoldenTestError.noGoldenSVG(savedTo: url)
        }
    }

    // MARK: - Basic Shape Tests

    @Test("SVG Golden: Basic squircle")
    @MainActor
    func basicSquircle() throws {
        let svg = try renderSVG(
            background: .solid(CSSColor("#3366FF")),
            cornerStyle: .squircle
        )

        let matches = try compareSVG(svg, toGoldenNamed: "basic-squircle")
        #expect(matches, "Basic squircle SVG should match golden")
    }

    @Test("SVG Golden: Rounded corners")
    @MainActor
    func roundedCorners() throws {
        let svg = try renderSVG(
            background: .solid(CSSColor("#FF6600")),
            cornerStyle: .rounded
        )

        let matches = try compareSVG(svg, toGoldenNamed: "rounded-corners")
        #expect(matches, "Rounded corners SVG should match golden")
    }

    @Test("SVG Golden: Square corners")
    @MainActor
    func squareCorners() throws {
        let svg = try renderSVG(
            background: .solid(CSSColor("#00CC66")),
            cornerStyle: .none
        )

        let matches = try compareSVG(svg, toGoldenNamed: "square-corners")
        #expect(matches, "Square corners SVG should match golden")
    }

    // MARK: - Gradient Tests

    @Test("SVG Golden: Linear gradient")
    @MainActor
    func linearGradient() throws {
        let svg = try renderSVG(
            background: Background("linear-gradient(to bottom, #FF6600, #CC0066)")
        )

        let matches = try compareSVG(svg, toGoldenNamed: "linear-gradient")
        #expect(matches, "Linear gradient SVG should match golden")
    }

    @Test("SVG Golden: Radial gradient")
    @MainActor
    func radialGradient() throws {
        let svg = try renderSVG(
            background: Background("radial-gradient(#FFCC00, #FF6600)")
        )

        let matches = try compareSVG(svg, toGoldenNamed: "radial-gradient")
        #expect(matches, "Radial gradient SVG should match golden")
    }

    @Test("SVG Golden: Angular gradient")
    @MainActor
    func angularGradient() throws {
        let svg = try renderSVG(
            background: Background("angular-gradient(#FF0000, #00FF00, #0000FF, #FF0000)")
        )

        let matches = try compareSVG(svg, toGoldenNamed: "angular-gradient")
        #expect(matches, "Angular gradient SVG should match golden")
    }

    // MARK: - Label Tests

    @Test("SVG Golden: Corner ribbon")
    @MainActor
    func cornerRibbon() throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let matches = try compareSVG(svg, toGoldenNamed: "corner-ribbon")
        #expect(matches, "Corner ribbon SVG should match golden")
    }

    @Test("SVG Golden: Edge ribbon")
    @MainActor
    func edgeRibbon() throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("TOP"), position: .top, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF"))
            ]
        )

        let matches = try compareSVG(svg, toGoldenNamed: "edge-ribbon")
        #expect(matches, "Edge ribbon SVG should match golden")
    }

    @Test("SVG Golden: Pill label")
    @MainActor
    func pillLabel() throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000"))
            ]
        )

        let matches = try compareSVG(svg, toGoldenNamed: "pill-label")
        #expect(matches, "Pill label SVG should match golden")
    }

    @Test("SVG Golden: All label positions")
    @MainActor
    func allLabelPositions() throws {
        let svg = try renderSVG(
            labels: [
                IconLabel(content: .text("TL"), position: .topLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("TR"), position: .topRight, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
                IconLabel(content: .text("T"), position: .top, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("P"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            ]
        )

        let matches = try compareSVG(svg, toGoldenNamed: "all-label-positions")
        #expect(matches, "All label positions SVG should match golden")
    }

    // MARK: - Center Content Tests

    @Test("SVG Golden: Center text")
    @MainActor
    func centerText() throws {
        let svg = try renderSVG(
            centerContent: CenterContent(content: .text("A"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let matches = try compareSVG(svg, toGoldenNamed: "center-text")
        #expect(matches, "Center text SVG should match golden")
    }

    @Test("SVG Golden: Center SF Symbol")
    @MainActor
    func centerSFSymbol() throws {
        let svg = try renderSVG(
            centerContent: CenterContent(content: .sfSymbol("swift"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5)
        )

        let matches = try compareSVG(svg, toGoldenNamed: "center-sf-symbol")
        #expect(matches, "Center SF Symbol SVG should match golden")
    }

    @Test("SVG Golden: Center rotated")
    @MainActor
    func centerRotated() throws {
        let svg = try renderSVG(
            centerContent: CenterContent(content: .sfSymbol("arrow.up"), color: CSSColor("#FFFFFF"), sizeRatio: 0.5, rotation: 45)
        )

        let matches = try compareSVG(svg, toGoldenNamed: "center-rotated")
        #expect(matches, "Center rotated SVG should match golden")
    }

    // MARK: - Complex Tests

    @Test("SVG Golden: Kitchen sink")
    @MainActor
    func kitchenSink() throws {
        let svg = try renderSVG(
            background: Background("linear-gradient(135deg, #667eea, #764ba2)"),
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
                IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            ],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: CSSColor("#FFFFFF"), sizeRatio: 0.4)
        )

        let matches = try compareSVG(svg, toGoldenNamed: "kitchen-sink")
        #expect(matches, "Kitchen sink SVG should match golden")
    }
}

enum SVGGoldenTestError: Error {
    case noGoldenSVG(savedTo: URL)
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
