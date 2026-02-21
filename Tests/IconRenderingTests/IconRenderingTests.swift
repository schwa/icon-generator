import Testing
import IconRendering
import SwiftUI

@Suite("IconRendering Tests")
struct IconRenderingTests {

    // MARK: - CSSColor Tests

    @Test("CSSColor hex parsing")
    func cssColorHexParsing() {
        let red = CSSColor("#FF0000")
        let components = red.parse()
        #expect(components != nil)
        #expect(components?.red == 1.0)
        #expect(components?.green == 0.0)
        #expect(components?.blue == 0.0)

        let shortHex = CSSColor("#F00")
        let shortComponents = shortHex.parse()
        #expect(shortComponents != nil)
        #expect(shortComponents?.red == 1.0)
    }

    @Test("CSSColor named colors")
    func cssColorNamedColors() {
        let red = CSSColor("red")
        #expect(red.color() != nil)

        let blue = CSSColor("blue")
        #expect(blue.color() != nil)

        let invalid = CSSColor("notacolor")
        // Invalid colors may still return something based on implementation
    }

    @Test("CSSColor rgba parsing")
    func cssColorRgbaParsing() {
        let rgba = CSSColor("rgba(255, 128, 0, 0.5)")
        let components = rgba.parse()
        #expect(components != nil)
        #expect(components?.red == 1.0)
        #expect(abs((components?.green ?? 0) - 0.502) < 0.01)
        #expect(components?.blue == 0.0)
        #expect(components?.alpha == 0.5)
    }

    // MARK: - Background Tests

    @Test("Background solid color")
    func backgroundSolidColor() {
        let bg = Background("#FF0000")
        if case .solid(let color) = bg {
            #expect(color.rawValue == "#FF0000")
        } else {
            Issue.record("Expected solid background")
        }
    }

    @Test("Background linear gradient")
    func backgroundLinearGradient() {
        let bg = Background("linear-gradient(to bottom, red, blue)")
        if case .linearGradient(let colors, let start, let end) = bg {
            #expect(colors.count == 2)
            #expect(start == .top)
            #expect(end == .bottom)
        } else {
            Issue.record("Expected linear gradient background")
        }
    }

    @Test("Background radial gradient")
    func backgroundRadialGradient() {
        let bg = Background("radial-gradient(#FF0000, #0000FF)")
        if case .radialGradient(let colors, _, _, _) = bg {
            #expect(colors.count == 2)
        } else {
            Issue.record("Expected radial gradient background")
        }
    }

    // MARK: - Label Tests

    @Test("LabelContent parsing")
    func labelContentParsing() {
        let text = LabelContent.parse("Hello")
        if case .text(let str) = text {
            #expect(str == "Hello")
        } else {
            Issue.record("Expected text content")
        }

        let symbol = LabelContent.parse("sf:star.fill")
        if case .sfSymbol(let name) = symbol {
            #expect(name == "star.fill")
        } else {
            Issue.record("Expected SF Symbol content")
        }

        let image = LabelContent.parse("@/path/to/image.png")
        if case .image(let url) = image {
            #expect(url.path == "/path/to/image.png")
        } else {
            Issue.record("Expected image content")
        }
    }

    @Test("IconLabel creation")
    func iconLabelCreation() {
        let label = IconLabel(
            content: .text("BETA"),
            position: .topRight,
            backgroundColor: CSSColor("#FF0000"),
            foregroundColor: CSSColor("#FFFFFF")
        )

        #expect(label.position == .topRight)
        #expect(label.resolvedBackgroundColor != Color.clear)
    }

    // MARK: - CenterContent Tests

    @Test("CenterContentType parsing")
    func centerContentTypeParsing() {
        let text = CenterContentType.parse("Hello")
        if case .text(let str) = text {
            #expect(str == "Hello")
        } else {
            Issue.record("Expected text content")
        }

        let symbol = CenterContentType.parse("sf:swift")
        if case .sfSymbol(let name) = symbol {
            #expect(name == "swift")
        } else {
            Issue.record("Expected SF Symbol content")
        }
    }

    // MARK: - IconGeometry Tests

    @Test("IconGeometry edge ribbon rect")
    func iconGeometryEdgeRibbonRect() {
        let size = CGSize(width: 100, height: 100)

        let topRect = IconGeometry.edgeRibbonRect(for: .top, in: size)
        #expect(topRect.origin.y == 0)
        #expect(topRect.width == 100)

        let bottomRect = IconGeometry.edgeRibbonRect(for: .bottom, in: size)
        #expect(bottomRect.maxY == 100)

        let leftRect = IconGeometry.edgeRibbonRect(for: .left, in: size)
        #expect(leftRect.origin.x == 0)

        let rightRect = IconGeometry.edgeRibbonRect(for: .right, in: size)
        #expect(rightRect.maxX == 100)
    }

    @Test("IconGeometry corner ribbon path")
    func iconGeometryCornerRibbonPath() {
        let size = CGSize(width: 100, height: 100)

        let topLeftPath = IconGeometry.cornerRibbonPath(for: .topLeft, in: size)
        #expect(!topLeftPath.isEmpty)

        let topRightPath = IconGeometry.cornerRibbonPath(for: .topRight, in: size)
        #expect(!topRightPath.isEmpty)
    }

    @Test("IconGeometry icon path")
    func iconGeometryIconPath() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

        let squirclePath = IconGeometry.iconPath(in: rect, cornerStyle: .squircle, cornerRadius: 0.2)
        #expect(!squirclePath.isEmpty)

        let roundedPath = IconGeometry.iconPath(in: rect, cornerStyle: .rounded, cornerRadius: 0.2)
        #expect(!roundedPath.isEmpty)

        let nonePath = IconGeometry.iconPath(in: rect, cornerStyle: .none, cornerRadius: 0.2)
        #expect(!nonePath.isEmpty)
    }

    // MARK: - CornerStyle Tests

    @Test("CornerStyle roundedCornerStyle")
    func cornerStyleRoundedCornerStyle() {
        #expect(CornerStyle.none.roundedCornerStyle == nil)
        #expect(CornerStyle.rounded.roundedCornerStyle == .circular)
        #expect(CornerStyle.squircle.roundedCornerStyle == .continuous)
    }
}
