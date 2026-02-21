import Foundation
import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers

@testable import icon_generator

/// Test suite that generates example icons to a temporary directory
@Suite("Icon Generator Examples")
struct IconGeneratorExampleTests {
    let outputDirectory: URL

    init() throws {
        outputDirectory = URL(fileURLWithPath: "/tmp/icon-generator-test-images", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        print("📁 Output directory: \(outputDirectory.path)")
    }

    // MARK: - Helper Methods

    @MainActor
    private func renderAndSave(
        name: String,
        background: Background = .white,
        size: Int = 512,
        cornerStyle: CornerStyle = .squircle,
        cornerRadiusRatio: Double = 0.2237,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) throws {
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
            Issue.record("Failed to render image: \(name)")
            return
        }

        let url = outputDirectory.appendingPathComponent("\(name).png")
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            Issue.record("Failed to create destination: \(name)")
            return
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            Issue.record("Failed to write PNG: \(name)")
            return
        }

        print("✅ Generated: \(name).png")
    }

    // MARK: - Basic Shape Tests

    @Test("Corner styles")
    @MainActor
    func cornerStyles() throws {
        let styles: [(CornerStyle, String)] = [
            (.none, "corner-none"),
            (.rounded, "corner-rounded"),
            (.squircle, "corner-squircle"),
        ]

        for (style, name) in styles {
            try renderAndSave(
                name: name,
                background: Background("#3366FF"),
                cornerStyle: style
            )
        }
    }

    @Test("Corner radii")
    @MainActor
    func cornerRadii() throws {
        let radii: [Double] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]

        for radius in radii {
            try renderAndSave(
                name: "radius-\(Int(radius * 100))",
                background: Background("#FF6600"),
                cornerRadiusRatio: radius
            )
        }
    }

    // MARK: - Background Colors

    @Test("Background colors")
    @MainActor
    func backgroundColors() throws {
        let colors: [(String, String)] = [
            ("#FF0000", "bg-red"),
            ("#00FF00", "bg-green"),
            ("#0000FF", "bg-blue"),
            ("#FFFF00", "bg-yellow"),
            ("#FF00FF", "bg-magenta"),
            ("#00FFFF", "bg-cyan"),
            ("#000000", "bg-black"),
            ("#FFFFFF", "bg-white"),
            ("#333333", "bg-dark-gray"),
            ("#CCCCCC", "bg-light-gray"),
            ("#F05138", "bg-swift-orange"),
            ("#5856D6", "bg-purple"),
            ("#34C759", "bg-apple-green"),
            ("#FF9500", "bg-orange"),
            ("#007AFF", "bg-ios-blue"),
        ]

        for (hex, name) in colors {
            try renderAndSave(
                name: name,
                background: Background(hex)
            )
        }
    }

    // MARK: - Center Content

    @Test("Center content - text")
    @MainActor
    func centerContentText() throws {
        let texts = ["A", "Z", "!", "42", "Hi"]

        for text in texts {
            try renderAndSave(
                name: "center-text-\(text)",
                background: Background("#3366FF"),
                centerContent: CenterContent(
                    content: .text(text),
                    color: .white,
                    sizeRatio: 0.5
                )
            )
        }
    }

    @Test("Center content - SF Symbols")
    @MainActor
    func centerContentSFSymbols() throws {
        let symbols = [
            "swift",
            "star.fill",
            "heart.fill",
            "bolt.fill",
            "flame.fill",
            "leaf.fill",
            "cloud.fill",
            "moon.fill",
            "sun.max.fill",
            "bell.fill",
            "gear",
            "house.fill",
            "person.fill",
            "envelope.fill",
            "phone.fill",
            "camera.fill",
            "photo.fill",
            "music.note",
            "play.fill",
            "checkmark.circle.fill",
        ]

        for symbol in symbols {
            let safeName = symbol.replacingOccurrences(of: ".", with: "-")
            try renderAndSave(
                name: "center-sf-\(safeName)",
                background: Background("#5856D6"),
                centerContent: CenterContent(
                    content: .sfSymbol(symbol),
                    color: .white,
                    sizeRatio: 0.5
                )
            )
        }
    }

    @Test("Center content - sizes")
    @MainActor
    func centerContentSizes() throws {
        let sizes: [Double] = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]

        for size in sizes {
            try renderAndSave(
                name: "center-size-\(Int(size * 100))",
                background: Background("#34C759"),
                centerContent: CenterContent(
                    content: .sfSymbol("star.fill"),
                    color: .white,
                    sizeRatio: size
                )
            )
        }
    }

    // MARK: - Edge Ribbon Labels

    @Test("Edge ribbon labels")
    @MainActor
    func edgeRibbonLabels() throws {
        let positions: [LabelPosition] = [.top, .bottom, .left, .right]

        for position in positions {
            try renderAndSave(
                name: "ribbon-\(position.rawValue)",
                background: Background("#007AFF"),
                labels: [
                    IconLabel(
                        content: .text(position.rawValue.uppercased()),
                        position: position,
                        backgroundColor: .red,
                        foregroundColor: .white
                    )
                ]
            )
        }
    }

    // MARK: - Corner Ribbon Labels

    @Test("Corner ribbon labels")
    @MainActor
    func cornerRibbonLabels() throws {
        let positions: [LabelPosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        for position in positions {
            try renderAndSave(
                name: "corner-\(position.rawValue)",
                background: Background("#FF9500"),
                labels: [
                    IconLabel(
                        content: .text("NEW"),
                        position: position,
                        backgroundColor: .red,
                        foregroundColor: .white
                    )
                ]
            )
        }

        // All corners at once
        try renderAndSave(
            name: "corner-all",
            background: Background("#FF9500"),
            labels: positions.map { position in
                IconLabel(
                    content: .text("!"),
                    position: position,
                    backgroundColor: .red,
                    foregroundColor: .white
                )
            }
        )
    }

    // MARK: - Pill Labels

    @Test("Pill labels")
    @MainActor
    func pillLabels() throws {
        let positions: [LabelPosition] = [.pillLeft, .pillCenter, .pillRight]

        for position in positions {
            try renderAndSave(
                name: "pill-\(position.rawValue)",
                background: Background("#5856D6"),
                labels: [
                    IconLabel(
                        content: .text("v1.0"),
                        position: position,
                        backgroundColor: .black,
                        foregroundColor: .white
                    )
                ]
            )
        }

        // All pills at once
        try renderAndSave(
            name: "pill-all",
            background: Background("#5856D6"),
            labels: [
                IconLabel(content: .text("L"), position: .pillLeft, backgroundColor: .red, foregroundColor: .white),
                IconLabel(content: .text("C"), position: .pillCenter, backgroundColor: .green, foregroundColor: .white),
                IconLabel(content: .text("R"), position: .pillRight, backgroundColor: .blue, foregroundColor: .white),
            ]
        )
    }

    // MARK: - Label Colors

    @Test("Label colors")
    @MainActor
    func labelColors() throws {
        let colors: [(CSSColor, CSSColor, String)] = [
            (.red, .white, "red-white"),
            (.blue, .white, "blue-white"),
            (.green, .white, "green-white"),
            (.yellow, .black, "yellow-black"),
            (.black, .white, "black-white"),
            (.white, .black, "white-black"),
            (.orange, .white, "orange-white"),
            (.purple, .white, "purple-white"),
        ]

        for (bg, fg, name) in colors {
            try renderAndSave(
                name: "label-color-\(name)",
                background: Background("#CCCCCC"),
                labels: [
                    IconLabel(
                        content: .text("LABEL"),
                        position: .top,
                        backgroundColor: bg,
                        foregroundColor: fg
                    )
                ]
            )
        }
    }

    // MARK: - Label Content Types

    @Test("Label with SF Symbols")
    @MainActor
    func labelSFSymbols() throws {
        let symbols = ["star.fill", "heart.fill", "bolt.fill", "checkmark", "xmark"]

        for symbol in symbols {
            let safeName = symbol.replacingOccurrences(of: ".", with: "-")
            try renderAndSave(
                name: "label-sf-\(safeName)",
                background: Background("#007AFF"),
                labels: [
                    IconLabel(
                        content: .sfSymbol(symbol),
                        position: .topRight,
                        backgroundColor: CSSColor("#FFD700"),
                        foregroundColor: .black
                    )
                ]
            )
        }
    }

    // MARK: - Complex Combinations

    @Test("Combined: center + corner label")
    @MainActor
    func combinedCenterAndCorner() throws {
        try renderAndSave(
            name: "combo-center-corner",
            background: Background("#3366FF"),
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: .red, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )
    }

    @Test("Combined: center + pill")
    @MainActor
    func combinedCenterAndPill() throws {
        try renderAndSave(
            name: "combo-center-pill",
            background: Background("#34C759"),
            labels: [
                IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("leaf.fill"), color: .white, sizeRatio: 0.5)
        )
    }

    @Test("Combined: center + multiple labels")
    @MainActor
    func combinedCenterAndMultipleLabels() throws {
        try renderAndSave(
            name: "combo-full",
            background: Background("#F05138"),
            labels: [
                IconLabel(content: .text("NEW"), position: .topRight, backgroundColor: .blue, foregroundColor: .white),
                IconLabel(content: .text("v3.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white),
            ],
            centerContent: CenterContent(content: .sfSymbol("flame.fill"), color: .white, sizeRatio: 0.45)
        )
    }

    @Test("Combined: all edge ribbons")
    @MainActor
    func combinedAllEdgeRibbons() throws {
        try renderAndSave(
            name: "combo-all-edges",
            background: Background("#FFFFFF"),
            labels: [
                IconLabel(content: .text("TOP"), position: .top, backgroundColor: .red, foregroundColor: .white),
                IconLabel(content: .text("BOTTOM"), position: .bottom, backgroundColor: .blue, foregroundColor: .white),
                IconLabel(content: .text("LEFT"), position: .left, backgroundColor: .green, foregroundColor: .white),
                IconLabel(content: .text("RIGHT"), position: .right, backgroundColor: CSSColor("orange"), foregroundColor: .white),
            ]
        )
    }

    // MARK: - App Icon Style Examples

    @Test("App icon examples")
    @MainActor
    func appIconExamples() throws {
        // Swift app icon style
        try renderAndSave(
            name: "app-swift",
            background: Background("#F05138"),
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.55)
        )

        // Music app style
        try renderAndSave(
            name: "app-music",
            background: Background("#FC3C44"),
            centerContent: CenterContent(content: .sfSymbol("music.note"), color: .white, sizeRatio: 0.5)
        )

        // Photos app style
        try renderAndSave(
            name: "app-photos",
            background: Background("#FFFFFF"),
            centerContent: CenterContent(content: .sfSymbol("photo.on.rectangle.angled"), color: CSSColor("#FF9500"), sizeRatio: 0.5)
        )

        // Settings app style
        try renderAndSave(
            name: "app-settings",
            background: Background("#8E8E93"),
            centerContent: CenterContent(content: .sfSymbol("gear"), color: .white, sizeRatio: 0.55)
        )

        // Mail app style
        try renderAndSave(
            name: "app-mail",
            background: Background("#007AFF"),
            centerContent: CenterContent(content: .sfSymbol("envelope.fill"), color: .white, sizeRatio: 0.45)
        )

        // Weather app style
        try renderAndSave(
            name: "app-weather",
            background: Background("#5AC8FA"),
            centerContent: CenterContent(content: .sfSymbol("sun.max.fill"), color: CSSColor("#FFD700"), sizeRatio: 0.5)
        )

        // Beta app
        try renderAndSave(
            name: "app-beta",
            background: Background("#5856D6"),
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF3B30"), foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("testtube.2"), color: .white, sizeRatio: 0.45)
        )

        // Debug build
        try renderAndSave(
            name: "app-debug",
            background: Background("#34C759"),
            labels: [
                IconLabel(content: .text("DEBUG"), position: .bottom, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("ant.fill"), color: .white, sizeRatio: 0.4)
        )

        // Versioned release
        try renderAndSave(
            name: "app-versioned",
            background: Background("#007AFF"),
            labels: [
                IconLabel(content: .text("v2.1.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("shippingbox.fill"), color: .white, sizeRatio: 0.4)
        )
    }

    // MARK: - Gradient-like Effects (multi-color schemes)

    @Test("Color scheme examples")
    @MainActor
    func colorSchemeExamples() throws {
        // Dark mode style
        try renderAndSave(
            name: "scheme-dark",
            background: Background("#1C1C1E"),
            centerContent: CenterContent(content: .sfSymbol("moon.fill"), color: CSSColor("#BF5AF2"), sizeRatio: 0.5)
        )

        // Light mode style
        try renderAndSave(
            name: "scheme-light",
            background: Background("#F2F2F7"),
            centerContent: CenterContent(content: .sfSymbol("sun.max.fill"), color: CSSColor("#FF9500"), sizeRatio: 0.5)
        )

        // Neon style
        try renderAndSave(
            name: "scheme-neon",
            background: Background("#000000"),
            labels: [
                IconLabel(content: .text("NEON"), position: .bottom, backgroundColor: CSSColor("#39FF14"), foregroundColor: .black)
            ],
            centerContent: CenterContent(content: .sfSymbol("bolt.fill"), color: CSSColor("#39FF14"), sizeRatio: 0.5)
        )

        // Pastel style
        try renderAndSave(
            name: "scheme-pastel",
            background: Background("#FFE5EC"),
            centerContent: CenterContent(content: .sfSymbol("heart.fill"), color: CSSColor("#FF8FAB"), sizeRatio: 0.5)
        )
    }

    // MARK: - Size Variations

    @Test("Size variations")
    @MainActor
    func sizeVariations() throws {
        let sizes = [64, 128, 256, 512, 1024]

        for size in sizes {
            try renderAndSave(
                name: "size-\(size)",
                background: Background("#007AFF"),
                size: size,
                centerContent: CenterContent(content: .sfSymbol("star.fill"), color: .white, sizeRatio: 0.5)
            )
        }
    }

    // MARK: - App Icon Set Generation

    @Test("App icon set - iOS")
    @MainActor
    func appIconSetIOS() throws {
        let iconSetURL = outputDirectory.appendingPathComponent("TestiOS.appiconset")
        try AppIconSetGenerator.generate(
            at: iconSetURL.path,
            platform: .ios,
            background: Background("#007AFF"),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.2237,
            labels: [],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )
        print("✅ Generated: TestiOS.appiconset")
    }

    @Test("App icon set - macOS")
    @MainActor
    func appIconSetMacOS() throws {
        let iconSetURL = outputDirectory.appendingPathComponent("TestmacOS.appiconset")
        try AppIconSetGenerator.generate(
            at: iconSetURL.path,
            platform: .macos,
            background: Background("#F05138"),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.2237,
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: .blue, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )
        print("✅ Generated: TestmacOS.appiconset")
    }

    @Test("App icon set - watchOS")
    @MainActor
    func appIconSetWatchOS() throws {
        let iconSetURL = outputDirectory.appendingPathComponent("TestwatchOS.appiconset")
        try AppIconSetGenerator.generate(
            at: iconSetURL.path,
            platform: .watchos,
            background: Background("#34C759"),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.2237,
            labels: [],
            centerContent: CenterContent(content: .sfSymbol("heart.fill"), color: .white, sizeRatio: 0.5)
        )
        print("✅ Generated: TestwatchOS.appiconset")
    }

    @Test("App icon set - Universal")
    @MainActor
    func appIconSetUniversal() throws {
        let iconSetURL = outputDirectory.appendingPathComponent("TestUniversal.appiconset")
        try AppIconSetGenerator.generate(
            at: iconSetURL.path,
            platform: .universal,
            background: Background("#5856D6"),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.2237,
            labels: [
                IconLabel(content: .text("v1.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("star.fill"), color: CSSColor("#FFD700"), sizeRatio: 0.5)
        )
        print("✅ Generated: TestUniversal.appiconset")
    }

    // MARK: - Center Alignment Options

    @Test("Center alignment - visual")
    @MainActor
    func centerAlignmentVisual() throws {
        try renderAndSave(
            name: "align-visual",
            background: .black,
            centerContent: CenterContent(
                content: .text("Ə"),
                color: .white,
                sizeRatio: 0.8,
                alignment: .visual
            )
        )
    }

    @Test("Center alignment - typographic")
    @MainActor
    func centerAlignmentTypographic() throws {
        try renderAndSave(
            name: "align-typographic",
            background: .black,
            centerContent: CenterContent(
                content: .text("Ə"),
                color: .white,
                sizeRatio: 0.8,
                alignment: .typographic
            )
        )
    }

    @Test("Center anchor - baseline")
    @MainActor
    func centerAnchorBaseline() throws {
        try renderAndSave(
            name: "anchor-baseline",
            background: Background("#007AFF"),
            centerContent: CenterContent(
                content: .text("Ag"),
                color: .white,
                sizeRatio: 0.5,
                alignment: .typographic,
                anchor: .baseline
            )
        )
    }

    @Test("Center anchor - cap")
    @MainActor
    func centerAnchorCap() throws {
        try renderAndSave(
            name: "anchor-cap",
            background: Background("#007AFF"),
            centerContent: CenterContent(
                content: .text("Ag"),
                color: .white,
                sizeRatio: 0.5,
                alignment: .typographic,
                anchor: .cap
            )
        )
    }

    @Test("Center y-offset")
    @MainActor
    func centerYOffset() throws {
        try renderAndSave(
            name: "offset-up",
            background: Background("#34C759"),
            centerContent: CenterContent(
                content: .text("ə"),
                color: .white,
                sizeRatio: 0.6,
                alignment: .typographic,
                anchor: .center,
                yOffset: 0.15
            )
        )

        try renderAndSave(
            name: "offset-down",
            background: Background("#FF3B30"),
            centerContent: CenterContent(
                content: .text("ə"),
                color: .white,
                sizeRatio: 0.6,
                alignment: .typographic,
                anchor: .center,
                yOffset: -0.15
            )
        )
        print("✅ Generated: TestUniversal.appiconset")
    }

    // MARK: - Image Embedding

    /// Creates a simple test image (a colored circle) and returns its URL
    private func createTestImage(color: NSColor, size: Int = 256) throws -> URL {
        let imageSize = NSSize(width: size, height: size)
        let image = NSImage(size: imageSize)

        image.lockFocus()
        color.setFill()
        let circlePath = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
        circlePath.fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test image"])
        }

        let url = outputDirectory.appendingPathComponent("test-image-\(color.description.hashValue).png")
        try pngData.write(to: url)
        return url
    }

    @Test("Center content - embedded image")
    @MainActor
    func centerContentImage() throws {
        // Create test images
        let redCircleURL = try createTestImage(color: .red)
        let blueCircleURL = try createTestImage(color: .blue)
        let greenCircleURL = try createTestImage(color: .green)

        // Test center image with default size
        try renderAndSave(
            name: "center-image-red",
            background: Background("#FFFFFF"),
            centerContent: CenterContent(
                content: .image(redCircleURL),
                color: .black, // color is ignored for images
                sizeRatio: 0.5
            )
        )

        // Test center image with larger size
        try renderAndSave(
            name: "center-image-blue-large",
            background: Background("#333333"),
            centerContent: CenterContent(
                content: .image(blueCircleURL),
                color: .white,
                sizeRatio: 0.7
            )
        )

        // Test center image with smaller size
        try renderAndSave(
            name: "center-image-green-small",
            background: Background("#FFCC00"),
            centerContent: CenterContent(
                content: .image(greenCircleURL),
                color: .white,
                sizeRatio: 0.3
            )
        )
    }

    @Test("Center content - image with y-offset")
    @MainActor
    func centerContentImageWithOffset() throws {
        let circleURL = try createTestImage(color: .purple)

        try renderAndSave(
            name: "center-image-offset-up",
            background: Background("#007AFF"),
            centerContent: CenterContent(
                content: .image(circleURL),
                color: .white,
                sizeRatio: 0.4,
                yOffset: 0.2
            )
        )

        try renderAndSave(
            name: "center-image-offset-down",
            background: Background("#FF3B30"),
            centerContent: CenterContent(
                content: .image(circleURL),
                color: .white,
                sizeRatio: 0.4,
                yOffset: -0.2
            )
        )
    }

    @Test("Label content - embedded image in corner ribbon")
    @MainActor
    func labelImageCornerRibbon() throws {
        let starURL = try createTestImage(color: .yellow, size: 64)

        // Image in top-right corner
        try renderAndSave(
            name: "label-image-topRight",
            background: Background("#5856D6"),
            labels: [
                IconLabel(
                    content: .image(starURL),
                    position: .topRight,
                    backgroundColor: .red,
                    foregroundColor: .white
                )
            ]
        )

        // Image in all corners
        try renderAndSave(
            name: "label-image-all-corners",
            background: Background("#34C759"),
            labels: [
                IconLabel(content: .image(starURL), position: .topLeft, backgroundColor: .red, foregroundColor: .white),
                IconLabel(content: .image(starURL), position: .topRight, backgroundColor: .blue, foregroundColor: .white),
                IconLabel(content: .image(starURL), position: .bottomLeft, backgroundColor: .green, foregroundColor: .white),
                IconLabel(content: .image(starURL), position: .bottomRight, backgroundColor: .orange, foregroundColor: .white),
            ]
        )
    }

    @Test("Label content - embedded image in edge ribbon")
    @MainActor
    func labelImageEdgeRibbon() throws {
        let iconURL = try createTestImage(color: .cyan, size: 64)

        try renderAndSave(
            name: "label-image-top",
            background: Background("#FF9500"),
            labels: [
                IconLabel(
                    content: .image(iconURL),
                    position: .top,
                    backgroundColor: .black,
                    foregroundColor: .white
                )
            ]
        )

        try renderAndSave(
            name: "label-image-bottom",
            background: Background("#FF9500"),
            labels: [
                IconLabel(
                    content: .image(iconURL),
                    position: .bottom,
                    backgroundColor: .black,
                    foregroundColor: .white
                )
            ]
        )
    }

    @Test("Label content - embedded image in pill")
    @MainActor
    func labelImagePill() throws {
        let badgeURL = try createTestImage(color: .magenta, size: 48)

        try renderAndSave(
            name: "label-image-pill-center",
            background: Background("#007AFF"),
            labels: [
                IconLabel(
                    content: .image(badgeURL),
                    position: .pillCenter,
                    backgroundColor: .white,
                    foregroundColor: .black
                )
            ]
        )

        // All pill positions with images
        try renderAndSave(
            name: "label-image-pill-all",
            background: Background("#5856D6"),
            labels: [
                IconLabel(content: .image(badgeURL), position: .pillLeft, backgroundColor: .red, foregroundColor: .white),
                IconLabel(content: .image(badgeURL), position: .pillCenter, backgroundColor: .white, foregroundColor: .black),
                IconLabel(content: .image(badgeURL), position: .pillRight, backgroundColor: .green, foregroundColor: .white),
            ]
        )
    }

    @Test("Combined: center image with labels")
    @MainActor
    func combinedCenterImageWithLabels() throws {
        let logoURL = try createTestImage(color: .white, size: 256)

        try renderAndSave(
            name: "combo-center-image-corner-label",
            background: Background("#F05138"),
            labels: [
                IconLabel(content: .text("NEW"), position: .topRight, backgroundColor: .blue, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .image(logoURL), color: .white, sizeRatio: 0.45)
        )

        try renderAndSave(
            name: "combo-center-image-pill-label",
            background: Background("#34C759"),
            labels: [
                IconLabel(content: .text("v1.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .image(logoURL), color: .white, sizeRatio: 0.5)
        )
    }

    @Test("Combined: center SF symbol with image labels")
    @MainActor
    func combinedCenterSymbolWithImageLabels() throws {
        let badgeURL = try createTestImage(color: .yellow, size: 64)

        try renderAndSave(
            name: "combo-center-symbol-image-labels",
            background: Background("#007AFF"),
            labels: [
                IconLabel(content: .image(badgeURL), position: .topRight, backgroundColor: .red, foregroundColor: .white),
                IconLabel(content: .image(badgeURL), position: .pillCenter, backgroundColor: .black, foregroundColor: .white),
            ],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )
    }

    // MARK: - Rotation

    @Test("Center content - rotation")
    @MainActor
    func centerContentRotation() throws {
        // Rotate SF symbol 45 degrees
        try renderAndSave(
            name: "rotation-center-45",
            background: Background("#007AFF"),
            centerContent: CenterContent(
                content: .sfSymbol("arrow.up"),
                color: .white,
                sizeRatio: 0.5,
                rotation: 45
            )
        )

        // Rotate SF symbol 90 degrees
        try renderAndSave(
            name: "rotation-center-90",
            background: Background("#34C759"),
            centerContent: CenterContent(
                content: .sfSymbol("arrow.up"),
                color: .white,
                sizeRatio: 0.5,
                rotation: 90
            )
        )

        // Rotate text -30 degrees (counter-clockwise)
        try renderAndSave(
            name: "rotation-center-text-negative",
            background: Background("#FF9500"),
            centerContent: CenterContent(
                content: .text("A"),
                color: .white,
                sizeRatio: 0.6,
                rotation: -30
            )
        )

        // Rotate image 180 degrees
        let imageURL = try createTestImage(color: .red, size: 128)
        try renderAndSave(
            name: "rotation-center-image-180",
            background: Background("#5856D6"),
            centerContent: CenterContent(
                content: .image(imageURL),
                color: .white,
                sizeRatio: 0.5,
                rotation: 180
            )
        )
    }

    @Test("Label content - rotation")
    @MainActor
    func labelContentRotation() throws {
        // Rotate label content 15 degrees
        try renderAndSave(
            name: "rotation-label-15",
            background: Background("#007AFF"),
            labels: [
                IconLabel(
                    content: .text("SPIN"),
                    position: .top,
                    backgroundColor: .red,
                    foregroundColor: .white,
                    rotation: 15
                )
            ]
        )

        // Rotate pill label content
        try renderAndSave(
            name: "rotation-label-pill",
            background: Background("#34C759"),
            labels: [
                IconLabel(
                    content: .sfSymbol("star.fill"),
                    position: .pillCenter,
                    backgroundColor: .black,
                    foregroundColor: CSSColor("#FFD700"),
                    rotation: 45
                )
            ]
        )

        // Rotate corner label content (on top of diagonal rotation)
        try renderAndSave(
            name: "rotation-label-corner",
            background: Background("#FF3B30"),
            labels: [
                IconLabel(
                    content: .sfSymbol("bolt.fill"),
                    position: .topRight,
                    backgroundColor: CSSColor("#FFD700"),
                    foregroundColor: .black,
                    rotation: 90
                )
            ]
        )
    }

    @Test("Combined: rotation with offset")
    @MainActor
    func combinedRotationWithOffset() throws {
        // Combine rotation with y-offset
        try renderAndSave(
            name: "rotation-combo-offset",
            background: Background("#1C1C1E"),
            centerContent: CenterContent(
                content: .sfSymbol("airplane"),
                color: .white,
                sizeRatio: 0.5,
                yOffset: 0.1,
                rotation: -45
            )
        )
    }

    // MARK: - Kitchen Sink

    @Test("Kitchen sink - all features")
    @MainActor
    func kitchenSink() throws {
        let config = KitchenSinkGenerator.generate()
        let labels = try (config.labels ?? []).map { try $0.toIconLabel() }
        let centerContent = config.center?.toCenterContent()

        try renderAndSave(
            name: "kitchen-sink",
            background: Background(config.background),
            cornerStyle: config.cornerStyle,
            cornerRadiusRatio: config.cornerRadius,
            labels: labels,
            centerContent: centerContent
        )
    }

    // MARK: - IconRenderer Tests

    @Test("CanvasIconRenderer - basic rendering")
    @MainActor
    func canvasIconRendererBasic() throws {
        let iconSize = CGSize(width: 512, height: 512)
        let cornerRadiusRatio: CGFloat = 0.2237

        // Create a Canvas-based view that uses the new renderer
        let view = Canvas { context, size in
            var renderer = CanvasIconRenderer(
                context: context,
                size: size,
                cornerRadiusRatio: cornerRadiusRatio
            )

            renderIcon(
                to: &renderer,
                background: Background("#007AFF"),
                cornerStyle: .squircle,
                cornerRadius: cornerRadiusRatio,
                labels: [
                    IconLabel(content: .text("TEST"), position: .topRight, backgroundColor: .red, foregroundColor: .white)
                ],
                centerContent: CenterContent(content: .sfSymbol("star.fill"), color: .white, sizeRatio: 0.5)
            )
        }
        .frame(width: iconSize.width, height: iconSize.height)

        let imageRenderer = ImageRenderer(content: view)
        imageRenderer.scale = 1.0

        guard let cgImage = imageRenderer.cgImage else {
            Issue.record("Failed to render image with CanvasIconRenderer")
            return
        }

        let url = outputDirectory.appendingPathComponent("renderer-test-basic.png")
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            Issue.record("Failed to create destination")
            return
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            Issue.record("Failed to write PNG")
            return
        }

        print("✅ Generated: renderer-test-basic.png")
    }

    @Test("CanvasIconRenderer - comparison with SquircleView")
    @MainActor
    func canvasIconRendererComparison() throws {
        // Test config
        let iconSize: CGFloat = 512
        let cornerRadiusRatio: CGFloat = 0.2237
        let background = Background("#007AFF")
        let labels = [
            IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: .red, foregroundColor: .white)
        ]
        let centerContent = CenterContent(content: .sfSymbol("star.fill"), color: .white, sizeRatio: 0.5)

        // Render with original SquircleView
        let originalView = SquircleView(
            background: background,
            size: iconSize,
            cornerStyle: .squircle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: labels,
            centerContent: centerContent
        )

        let originalRenderer = ImageRenderer(content: originalView)
        originalRenderer.scale = 1.0
        guard let originalImage = originalRenderer.cgImage else {
            Issue.record("Failed to render original")
            return
        }

        // Render with new CanvasIconRenderer
        let rendererView = Canvas { context, size in
            var renderer = CanvasIconRenderer(
                context: context,
                size: size,
                cornerRadiusRatio: cornerRadiusRatio
            )
            renderIcon(
                to: &renderer,
                background: background,
                cornerStyle: .squircle,
                cornerRadius: cornerRadiusRatio,
                labels: labels,
                centerContent: centerContent
            )
        }
        .frame(width: iconSize, height: iconSize)

        let newRenderer = ImageRenderer(content: rendererView)
        newRenderer.scale = 1.0
        guard let newImage = newRenderer.cgImage else {
            Issue.record("Failed to render new")
            return
        }

        // Save both for visual comparison
        for (image, name) in [(originalImage, "compare-original"), (newImage, "compare-new")] {
            let url = outputDirectory.appendingPathComponent("\(name).png")
            guard let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            ) else { continue }
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
            print("✅ Generated: \(name).png")
        }
    }

    @Test("CanvasIconRenderer - all label types")
    @MainActor
    func canvasIconRendererAllLabels() throws {
        let iconSize: CGFloat = 512
        let cornerRadiusRatio: CGFloat = 0.2237

        let view = Canvas { context, size in
            var renderer = CanvasIconRenderer(
                context: context,
                size: size,
                cornerRadiusRatio: cornerRadiusRatio
            )

            renderIcon(
                to: &renderer,
                background: Background("#5856D6"),
                cornerStyle: .squircle,
                cornerRadius: cornerRadiusRatio,
                labels: [
                    // Edge ribbons
                    IconLabel(content: .text("TOP"), position: .top, backgroundColor: .red, foregroundColor: .white),
                    // Corner ribbons
                    IconLabel(content: .sfSymbol("star.fill"), position: .topLeft, backgroundColor: CSSColor("#FFD700"), foregroundColor: .black),
                    IconLabel(content: .text("NEW"), position: .topRight, backgroundColor: .green, foregroundColor: .white),
                    // Pills
                    IconLabel(content: .text("v1.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white),
                ],
                centerContent: nil
            )
        }
        .frame(width: iconSize, height: iconSize)

        let imageRenderer = ImageRenderer(content: view)
        imageRenderer.scale = 1.0

        guard let cgImage = imageRenderer.cgImage else {
            Issue.record("Failed to render image with CanvasIconRenderer")
            return
        }

        let url = outputDirectory.appendingPathComponent("renderer-test-all-labels.png")
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            Issue.record("Failed to create destination")
            return
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            Issue.record("Failed to write PNG")
            return
        }

        print("✅ Generated: renderer-test-all-labels.png")
    }

    @Test("CanvasIconRenderer - gradient background")
    @MainActor
    func canvasIconRendererGradient() throws {
        let iconSize: CGFloat = 512
        let cornerRadiusRatio: CGFloat = 0.2237

        // Compare gradient rendering
        let background = Background("linear-gradient(135deg, #667eea, #764ba2)")
        let centerContent = CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)

        // Original
        let originalView = SquircleView(
            background: background,
            size: iconSize,
            cornerStyle: .squircle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: [],
            centerContent: centerContent
        )

        // New renderer
        let newView = Canvas { context, size in
            var renderer = CanvasIconRenderer(context: context, size: size, cornerRadiusRatio: cornerRadiusRatio)
            renderIcon(to: &renderer, background: background, cornerStyle: .squircle, cornerRadius: cornerRadiusRatio, labels: [], centerContent: centerContent)
        }
        .frame(width: iconSize, height: iconSize)

        // Save both
        for (view, name) in [(AnyView(originalView), "gradient-compare-original"), (AnyView(newView), "gradient-compare-new")] {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0
            guard let cgImage = renderer.cgImage else { continue }

            let url = outputDirectory.appendingPathComponent("\(name).png")
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { continue }
            CGImageDestinationAddImage(destination, cgImage, nil)
            CGImageDestinationFinalize(destination)
            print("✅ Generated: \(name).png")
        }
    }

    @Test("CanvasIconRenderer - center rotation")
    @MainActor
    func canvasIconRendererRotation() throws {
        let iconSize: CGFloat = 512
        let cornerRadiusRatio: CGFloat = 0.2237

        let background = Background("#007AFF")
        let centerContent = CenterContent(content: .sfSymbol("arrow.up"), color: .white, sizeRatio: 0.5, rotation: 45)

        // Original
        let originalView = SquircleView(
            background: background,
            size: iconSize,
            cornerStyle: .squircle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: [],
            centerContent: centerContent
        )

        // New renderer
        let newView = Canvas { context, size in
            var renderer = CanvasIconRenderer(context: context, size: size, cornerRadiusRatio: cornerRadiusRatio)
            renderIcon(to: &renderer, background: background, cornerStyle: .squircle, cornerRadius: cornerRadiusRatio, labels: [], centerContent: centerContent)
        }
        .frame(width: iconSize, height: iconSize)

        // Save both
        for (view, name) in [(AnyView(originalView), "rotation-compare-original"), (AnyView(newView), "rotation-compare-new")] {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0
            guard let cgImage = renderer.cgImage else { continue }

            let url = outputDirectory.appendingPathComponent("\(name).png")
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { continue }
            CGImageDestinationAddImage(destination, cgImage, nil)
            CGImageDestinationFinalize(destination)
            print("✅ Generated: \(name).png")
        }
    }

    // MARK: - SVG Rendering

    @Test("SVG basic rendering")
    @MainActor
    func svgBasicRendering() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        renderIcon(
            to: &renderer,
            background: Background("#3366FF"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: [],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )

        let svg = renderer.render()

        // Basic sanity checks
        #expect(svg.contains("<?xml"))
        #expect(svg.contains("<svg"))
        #expect(svg.contains("</svg>"))
        #expect(svg.contains("width=\"512\""))
        #expect(svg.contains("height=\"512\""))
        // Color may have minor rounding differences (#3366FF vs #3265FF)
        #expect(svg.contains("#33") || svg.contains("#32"))

        // Save to file
        let url = outputDirectory.appendingPathComponent("svg-basic.svg")
        try svg.write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-basic.svg")
    }

    @Test("SVG with labels")
    @MainActor
    func svgWithLabels() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        let labels = [
            IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("v2.0"), position: .pillCenter, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
        ]

        renderIcon(
            to: &renderer,
            background: Background("#6633CC"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: labels,
            centerContent: CenterContent(content: .text("A"), color: .white, sizeRatio: 0.5)
        )

        let svg = renderer.render()

        // Check for labels
        #expect(svg.contains("BETA"))
        #expect(svg.contains("v2.0"))
        #expect(svg.contains("#FF0000"))

        let url = outputDirectory.appendingPathComponent("svg-labels.svg")
        try svg.write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-labels.svg")
    }

    @Test("SVG with gradient")
    @MainActor
    func svgWithGradient() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        renderIcon(
            to: &renderer,
            background: Background("linear-gradient(to bottom, #FF6600, #CC0066)"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: [
                IconLabel(content: .sfSymbol("star.fill"), position: .topLeft, backgroundColor: CSSColor("#FFD700"), foregroundColor: CSSColor("#000000")),
            ],
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )

        let svg = renderer.render()

        // Check for gradient definition
        #expect(svg.contains("<linearGradient"))
        #expect(svg.contains("<stop"))
        #expect(svg.contains("url(#"))

        let url = outputDirectory.appendingPathComponent("svg-gradient.svg")
        try svg.write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-gradient.svg")
    }

    @Test("SVG all edge ribbons")
    @MainActor
    func svgAllEdgeRibbons() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        let labels = [
            IconLabel(content: .text("TOP"), position: .top, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("BOTTOM"), position: .bottom, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("LEFT"), position: .left, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("RIGHT"), position: .right, backgroundColor: CSSColor("#FFFF00"), foregroundColor: CSSColor("#000000")),
        ]

        renderIcon(
            to: &renderer,
            background: Background("#888888"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: labels,
            centerContent: nil
        )

        let url = outputDirectory.appendingPathComponent("svg-edge-ribbons.svg")
        try renderer.render().write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-edge-ribbons.svg")
    }

    @Test("SVG all corner ribbons")
    @MainActor
    func svgAllCornerRibbons() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        let labels = [
            IconLabel(content: .sfSymbol("1.circle.fill"), position: .topLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .sfSymbol("2.circle.fill"), position: .topRight, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .sfSymbol("3.circle.fill"), position: .bottomLeft, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .sfSymbol("4.circle.fill"), position: .bottomRight, backgroundColor: CSSColor("#FFFF00"), foregroundColor: CSSColor("#000000")),
        ]

        renderIcon(
            to: &renderer,
            background: Background("#333333"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: labels,
            centerContent: nil
        )

        let url = outputDirectory.appendingPathComponent("svg-corner-ribbons.svg")
        try renderer.render().write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-corner-ribbons.svg")
    }

    @Test("SVG all pills")
    @MainActor
    func svgAllPills() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        let labels = [
            IconLabel(content: .text("LEFT"), position: .pillLeft, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .sfSymbol("star.fill"), position: .pillCenter, backgroundColor: CSSColor("#00FF00"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("RIGHT"), position: .pillRight, backgroundColor: CSSColor("#0000FF"), foregroundColor: CSSColor("#FFFFFF")),
        ]

        renderIcon(
            to: &renderer,
            background: Background("#9966CC"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: labels,
            centerContent: CenterContent(content: .sfSymbol("app.fill"), color: .white, sizeRatio: 0.4)
        )

        let url = outputDirectory.appendingPathComponent("svg-pills.svg")
        try renderer.render().write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-pills.svg")
    }

    @Test("SVG corner styles")
    @MainActor
    func svgCornerStyles() throws {
        let iconSize = CGSize(width: 512, height: 512)

        for (style, name) in [(CornerStyle.none, "none"), (.rounded, "rounded"), (.squircle, "squircle")] {
            var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)
            renderIcon(
                to: &renderer,
                background: Background("#3366FF"),
                cornerStyle: style,
                cornerRadius: 0.2237,
                labels: [],
                centerContent: CenterContent(content: .sfSymbol("square.fill"), color: .white, sizeRatio: 0.3)
            )
            let url = outputDirectory.appendingPathComponent("svg-corner-\(name).svg")
            try renderer.render().write(to: url, atomically: true, encoding: .utf8)
            print("✅ Generated: svg-corner-\(name).svg")
        }
    }

    @Test("SVG radial gradient")
    @MainActor
    func svgRadialGradient() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        renderIcon(
            to: &renderer,
            background: Background("radial-gradient(#FFCC00, #FF6600)"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: [],
            centerContent: CenterContent(content: .sfSymbol("sun.max.fill"), color: .white, sizeRatio: 0.5)
        )

        let svg = renderer.render()
        #expect(svg.contains("<radialGradient"))

        let url = outputDirectory.appendingPathComponent("svg-radial-gradient.svg")
        try svg.write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-radial-gradient.svg")
    }

    @Test("SVG kitchen sink")
    @MainActor
    func svgKitchenSink() throws {
        let iconSize = CGSize(width: 512, height: 512)
        var renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: 0.2237)

        let labels = [
            IconLabel(content: .sfSymbol("star.fill"), position: .topLeft, backgroundColor: CSSColor("#FFD700"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF0000"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("v2.0"), position: .pillLeft, backgroundColor: CSSColor("#FFFFFF"), foregroundColor: CSSColor("#000000")),
            IconLabel(content: .sfSymbol("sparkles"), position: .pillCenter, backgroundColor: CSSColor("rgba(0,0,0,0.5)"), foregroundColor: CSSColor("#FFD700")),
            IconLabel(content: .sfSymbol("checkmark.circle.fill"), position: .pillRight, backgroundColor: CSSColor("#00CC00"), foregroundColor: CSSColor("#FFFFFF")),
            IconLabel(content: .text("SALE"), position: .bottom, backgroundColor: CSSColor("#000000"), foregroundColor: CSSColor("#FFFFFF")),
        ]

        renderIcon(
            to: &renderer,
            background: Background("linear-gradient(135deg, #667eea, #764ba2)"),
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            labels: labels,
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.45)
        )

        let url = outputDirectory.appendingPathComponent("svg-kitchen-sink.svg")
        try renderer.render().write(to: url, atomically: true, encoding: .utf8)
        print("✅ Generated: svg-kitchen-sink.svg")
    }

    // MARK: - Gradient Backgrounds

    @Test("Gradient backgrounds")
    @MainActor
    func gradientBackgrounds() throws {
        // Linear gradient - vertical
        try renderAndSave(
            name: "gradient-linear-vertical",
            background: Background("linear-gradient(to bottom, #FF0000, #0000FF)"),
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.5)
        )

        // Linear gradient - diagonal
        try renderAndSave(
            name: "gradient-linear-45deg",
            background: Background("linear-gradient(45deg, orange, purple)"),
            centerContent: CenterContent(content: .sfSymbol("star.fill"), color: .white, sizeRatio: 0.5)
        )

        // Radial gradient
        try renderAndSave(
            name: "gradient-radial",
            background: Background("radial-gradient(#FFCC00, #FF6600)"),
            centerContent: CenterContent(content: .sfSymbol("sun.max.fill"), color: .white, sizeRatio: 0.5)
        )

        // Angular/conic gradient
        try renderAndSave(
            name: "gradient-angular",
            background: Background("angular-gradient(red, orange, yellow, green, blue, purple, red)"),
            centerContent: CenterContent(content: .sfSymbol("paintpalette.fill"), color: .white, sizeRatio: 0.5)
        )
    }
}

/// Separate suite that just prints the output directory for easy access
@Suite("Output Info", .serialized)
struct OutputInfoTests {
    @Test("Print output directory")
    func printOutputDirectory() {
        let outputDirectory = URL(fileURLWithPath: "/tmp/icon-generator-test-images", isDirectory: true)

        print("\n" + String(repeating: "=", count: 60))
        print("📊 ICON GENERATOR EXAMPLES")
        print(String(repeating: "=", count: 60))
        print("📁 Output directory:")
        print("   \(outputDirectory.path)")
        print("")
        print("🔍 To view: open \(outputDirectory.path)")
        print(String(repeating: "=", count: 60))

        if let files = try? FileManager.default.contentsOfDirectory(at: outputDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            let pngFiles = files.filter { $0.pathExtension == "png" }
            print("📝 Total files: \(pngFiles.count)")

            var totalSize: Int64 = 0
            for file in pngFiles {
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
            print("💾 Total size: \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))")
            print(String(repeating: "=", count: 60))
        }
    }
}
