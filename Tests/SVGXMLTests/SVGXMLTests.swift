import Testing
import SVGXML
import SwiftUI

@Suite("SVGXML Tests")
struct SVGXMLTests {

    @Test("XMLElement basic rendering")
    func xmlElementBasicRendering() {
        let element = SVGXML.XMLElement(name: "div", attributes: ["class": "test"], text: "Hello")
        let rendered = element.renderCompact()
        #expect(rendered.contains("<div"))
        #expect(rendered.contains("class=\"test\""))
        #expect(rendered.contains("Hello"))
        #expect(rendered.contains("</div>"))
    }

    @Test("XMLElement nested elements")
    func xmlElementNestedElements() {
        let child = SVGXML.XMLElement(name: "span", text: "Child")
        let parent = SVGXML.XMLElement(name: "div", children: [child])
        let rendered = parent.render()
        #expect(rendered.contains("<div>"))
        #expect(rendered.contains("<span>Child</span>"))
        #expect(rendered.contains("</div>"))
    }

    @Test("XMLElement self-closing")
    func xmlElementSelfClosing() {
        let element = SVGXML.XMLElement(name: "br")
        let rendered = element.renderCompact()
        #expect(rendered == "<br/>")
    }

    @Test("XMLElement attribute escaping")
    func xmlElementAttributeEscaping() {
        let element = SVGXML.XMLElement(name: "div", attributes: ["title": "Hello \"World\" & <Friends>"])
        let rendered = element.renderCompact()
        #expect(rendered.contains("&quot;"))
        #expect(rendered.contains("&amp;"))
        #expect(rendered.contains("&lt;"))
        #expect(rendered.contains("&gt;"))
    }

    @Test("SVG element helpers")
    func svgElementHelpers() {
        let rect = XMLElement.rect(x: 10, y: 20, width: 100, height: 50, fill: "#FF0000")
        let rendered = rect.renderCompact()
        #expect(rendered.contains("x=\"10\""))
        #expect(rendered.contains("y=\"20\""))
        #expect(rendered.contains("width=\"100\""))
        #expect(rendered.contains("height=\"50\""))
        #expect(rendered.contains("fill=\"#FF0000\""))
    }

    @Test("Path to SVG conversion")
    func pathToSVG() {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 100))
        path.closeSubpath()

        let svgPath = path.svgPathData()
        #expect(svgPath.contains("M0,0"))
        #expect(svgPath.contains("L100,0"))
        #expect(svgPath.contains("L100,100"))
        #expect(svgPath.contains("Z"))
    }

    @Test("Color to SVG conversion")
    func colorToSVG() {
        let red = Color.red.svgString()
        // Color.red may not be exactly #FF0000 due to color space
        #expect(red.hasPrefix("#"))

        let white = Color.white.svgString()
        #expect(white.hasPrefix("#"))
    }

    @Test("SVGDocument basic usage")
    func svgDocumentBasicUsage() {
        let doc = SVGDocument(width: 100, height: 100)
        doc.addRect(x: 0, y: 0, width: 100, height: 100, fill: "#FF0000")
        let svg = doc.render()

        #expect(svg.contains("<?xml"))
        #expect(svg.contains("<svg"))
        #expect(svg.contains("width=\"100\""))
        #expect(svg.contains("height=\"100\""))
        #expect(svg.contains("<rect"))
        #expect(svg.contains("</svg>"))
    }

    @Test("SVGDocument with clip path")
    func svgDocumentClipPath() {
        let doc = SVGDocument(width: 100, height: 100)
        var path = Path()
        path.addEllipse(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        let clipID = doc.addClipPath(path: path)

        #expect(!clipID.isEmpty)

        let svg = doc.render()
        #expect(svg.contains("<clipPath"))
        #expect(svg.contains("id=\"\(clipID)\""))
    }

    @Test("SVGTransform helpers")
    func svgTransformHelpers() {
        let translate = SVGTransform.translate(x: 10, y: 20)
        #expect(translate == "translate(10,20)")

        let rotate = SVGTransform.rotate(45)
        #expect(rotate == "rotate(45)")

        let rotateAround = SVGTransform.rotate(45, around: CGPoint(x: 50, y: 50))
        #expect(rotateAround == "rotate(45,50,50)")

        let scale = SVGTransform.scale(x: 2, y: 2)
        #expect(scale == "scale(2)")

        let scaleNonUniform = SVGTransform.scale(x: 2, y: 3)
        #expect(scaleNonUniform == "scale(2,3)")
    }
}
