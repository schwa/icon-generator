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
        let tmp = FileManager.default.temporaryDirectory
        outputDirectory = tmp.appendingPathComponent("icon-generator-examples", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        print("📁 Output directory: \(outputDirectory.path)")
    }

    // MARK: - Helper Methods

    @MainActor
    private func renderAndSave(
        name: String,
        backgroundColor: CSSColor = .white,
        size: Int = 512,
        cornerStyle: CornerStyle = .squircle,
        cornerRadiusRatio: Double = 0.2237,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) throws {
        let view = SquircleView(
            backgroundColor: backgroundColor,
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
                backgroundColor: CSSColor("#3366FF"),
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
                backgroundColor: CSSColor("#FF6600"),
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
                backgroundColor: CSSColor(hex)
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
                backgroundColor: CSSColor("#3366FF"),
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
                backgroundColor: CSSColor("#5856D6"),
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
                backgroundColor: CSSColor("#34C759"),
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
                backgroundColor: CSSColor("#007AFF"),
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
                backgroundColor: CSSColor("#FF9500"),
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
            backgroundColor: CSSColor("#FF9500"),
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
                backgroundColor: CSSColor("#5856D6"),
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
            backgroundColor: CSSColor("#5856D6"),
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
                backgroundColor: CSSColor("#CCCCCC"),
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
                backgroundColor: CSSColor("#007AFF"),
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
            backgroundColor: CSSColor("#3366FF"),
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
            backgroundColor: CSSColor("#34C759"),
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
            backgroundColor: CSSColor("#F05138"),
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
            backgroundColor: CSSColor("#FFFFFF"),
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
            backgroundColor: CSSColor("#F05138"),
            centerContent: CenterContent(content: .sfSymbol("swift"), color: .white, sizeRatio: 0.55)
        )

        // Music app style
        try renderAndSave(
            name: "app-music",
            backgroundColor: CSSColor("#FC3C44"),
            centerContent: CenterContent(content: .sfSymbol("music.note"), color: .white, sizeRatio: 0.5)
        )

        // Photos app style
        try renderAndSave(
            name: "app-photos",
            backgroundColor: CSSColor("#FFFFFF"),
            centerContent: CenterContent(content: .sfSymbol("photo.on.rectangle.angled"), color: CSSColor("#FF9500"), sizeRatio: 0.5)
        )

        // Settings app style
        try renderAndSave(
            name: "app-settings",
            backgroundColor: CSSColor("#8E8E93"),
            centerContent: CenterContent(content: .sfSymbol("gear"), color: .white, sizeRatio: 0.55)
        )

        // Mail app style
        try renderAndSave(
            name: "app-mail",
            backgroundColor: CSSColor("#007AFF"),
            centerContent: CenterContent(content: .sfSymbol("envelope.fill"), color: .white, sizeRatio: 0.45)
        )

        // Weather app style
        try renderAndSave(
            name: "app-weather",
            backgroundColor: CSSColor("#5AC8FA"),
            centerContent: CenterContent(content: .sfSymbol("sun.max.fill"), color: CSSColor("#FFD700"), sizeRatio: 0.5)
        )

        // Beta app
        try renderAndSave(
            name: "app-beta",
            backgroundColor: CSSColor("#5856D6"),
            labels: [
                IconLabel(content: .text("BETA"), position: .topRight, backgroundColor: CSSColor("#FF3B30"), foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("testtube.2"), color: .white, sizeRatio: 0.45)
        )

        // Debug build
        try renderAndSave(
            name: "app-debug",
            backgroundColor: CSSColor("#34C759"),
            labels: [
                IconLabel(content: .text("DEBUG"), position: .bottom, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("ant.fill"), color: .white, sizeRatio: 0.4)
        )

        // Versioned release
        try renderAndSave(
            name: "app-versioned",
            backgroundColor: CSSColor("#007AFF"),
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
            backgroundColor: CSSColor("#1C1C1E"),
            centerContent: CenterContent(content: .sfSymbol("moon.fill"), color: CSSColor("#BF5AF2"), sizeRatio: 0.5)
        )

        // Light mode style
        try renderAndSave(
            name: "scheme-light",
            backgroundColor: CSSColor("#F2F2F7"),
            centerContent: CenterContent(content: .sfSymbol("sun.max.fill"), color: CSSColor("#FF9500"), sizeRatio: 0.5)
        )

        // Neon style
        try renderAndSave(
            name: "scheme-neon",
            backgroundColor: CSSColor("#000000"),
            labels: [
                IconLabel(content: .text("NEON"), position: .bottom, backgroundColor: CSSColor("#39FF14"), foregroundColor: .black)
            ],
            centerContent: CenterContent(content: .sfSymbol("bolt.fill"), color: CSSColor("#39FF14"), sizeRatio: 0.5)
        )

        // Pastel style
        try renderAndSave(
            name: "scheme-pastel",
            backgroundColor: CSSColor("#FFE5EC"),
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
                backgroundColor: CSSColor("#007AFF"),
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
            backgroundColor: CSSColor("#007AFF"),
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
            backgroundColor: CSSColor("#F05138"),
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
            backgroundColor: CSSColor("#34C759"),
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
            backgroundColor: CSSColor("#5856D6"),
            cornerStyle: .squircle,
            cornerRadiusRatio: 0.2237,
            labels: [
                IconLabel(content: .text("v1.0"), position: .pillCenter, backgroundColor: .black, foregroundColor: .white)
            ],
            centerContent: CenterContent(content: .sfSymbol("star.fill"), color: CSSColor("#FFD700"), sizeRatio: 0.5)
        )
        print("✅ Generated: TestUniversal.appiconset")
    }
}

/// Separate suite that just prints the output directory for easy access
@Suite("Output Info", .serialized)
struct OutputInfoTests {
    @Test("Print output directory")
    func printOutputDirectory() {
        let tmp = FileManager.default.temporaryDirectory
        let outputDirectory = tmp.appendingPathComponent("icon-generator-examples", isDirectory: true)

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
