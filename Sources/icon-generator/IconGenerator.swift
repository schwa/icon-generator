import IconRendering
import ArgumentParser
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@main
struct IconGenerator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "icon-generator",
        abstract: "Generate a squircle icon as a PNG image or Xcode app icon set",
        discussion: """
            Options can be specified via CLI arguments or a JSON config file.
            CLI arguments override config file values.

            Output Formats:
              - Single PNG: --output icon.png
              - Single SVG: --output icon.svg
              - App Icon Set: --output AppIcon.appiconset --platform ios

            App Icon Platforms:
              ios        Single 1024x1024 icon for iOS/iPadOS
              macos      Multiple sizes (16-1024) for macOS
              watchos    Single 1024x1024 icon for watchOS
              universal  Combined iOS + macOS icons

            Corner Styles:
              none      Square corners (no rounding)
              rounded   Standard rounded corners (circular arcs)
              squircle  Continuous corners (iOS-style, default)

            JSON Config Example:
              {
                "background": "#3366FF",
                "output": "icon.png",
                "size": 1024,
                "corner-style": "squircle",
                "corner-radius": 0.2237,
                "platform": "ios",
                "labels": [
                  {"position": "topRight", "content": "BETA", "background-color": "#FF0000"},
                  {"position": "pillCenter", "content": "sf:star.fill", "foreground-color": "#FFD700"}
                ],
                "center": {
                  "content": "sf:swift",
                  "color": "#FFFFFF",
                  "size": 0.5
                }
              }

            Labels can be added using the --label option (repeatable).

            Label format: position:content[:backgroundColor[:foregroundColor]]

            Positions:
              Edge ribbons:    top, bottom, left, right
              Corner ribbons:  topLeft, topRight, bottomLeft, bottomRight
              Bottom pills:    pillLeft, pillCenter, pillRight

            Content:
              Text:      Just the text string (e.g., "BETA")
              Image:     Prefix with @ (e.g., "@/path/to/icon.png")
              SF Symbol: Prefix with sf: (e.g., "sf:star.fill")

            Colors: Hex format (e.g., #FF0000)
            Defaults: backgroundColor=#FF0000 (red), foregroundColor=#FFFFFF (white)

            Center content can be added with --center:
              --center "Hello"              Text with default color (#000000) and size (0.5)
              --center "@/path/to/img.png"  Image file
              --center "sf:star.fill"       SF Symbol

            Examples:
              icon-generator --background "#3366FF" -o icon.png
              icon-generator --background "#3366FF" -o icon.svg
              icon-generator -o AppIcon.appiconset --platform ios --background "#FF0000"
              icon-generator -o AppIcon.appiconset --platform macos --center "sf:swift"
              icon-generator --config config.json
              --label topRight:BETA
              --center "sf:swift" --center-color "#F05138"
            """
    )

    @Option(name: .shortAndLong, help: "Path to JSON configuration file")
    var config: String?

    @Option(name: .long, help: "Background color or gradient (e.g., #FF0000, linear-gradient(to bottom, red, blue))")
    var background: String?

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String?

    @Option(name: .long, help: "Image size in pixels")
    var size: Int?

    @Option(name: .long, help: "Corner style: none, rounded, or squircle")
    var cornerStyle: CornerStyle?

    @Option(name: .long, help: "Corner radius ratio (0.0 to 0.5)")
    var cornerRadius: Double?

    @Option(name: .long, help: "App icon platform: ios, macos, watchos, or universal")
    var platform: AppIconPlatform?

    @Option(name: .long, parsing: .upToNextOption, help: "Label specification (repeatable)")
    var label: [LabelSpecification] = []

    @Option(name: .long, help: "Center content (text, @image path, or sf:symbol)")
    var center: String?

    @Option(name: .long, help: "Center content color in hex format")
    var centerColor: String?

    @Option(name: .long, help: "Center content size ratio (0.0 to 1.0)")
    var centerSize: Double?

    @Option(name: .long, help: "Center alignment mode: visual (glyph bounds) or typographic (font metrics)")
    var centerAlign: CenterAlignment?

    @Option(name: .long, help: "Center vertical anchor: baseline, cap, or center")
    var centerAnchor: CenterAnchor?

    @Option(name: .long, help: "Center vertical offset ratio (-1.0 to 1.0, positive moves up)")
    var centerYOffset: Double?

    @Option(name: .long, help: "Center rotation in degrees (positive = clockwise)")
    var centerRotation: Double?

    @Option(name: .long, help: "Font family for SVG text (default: system fonts)")
    var svgFont: String?

    @Flag(name: .long, help: "Output resolved configuration as JSON (no image generated)")
    var dumpConfig: Bool = false

    @Flag(name: .long, help: "Generate random icon configuration")
    var random: Bool = false

    @Flag(name: .long, help: "Generate an icon using every feature (kitchen sink demo)")
    var kitchenSink: Bool = false

    mutating func run() async throws {
        // If no meaningful arguments provided, show help
        let hasAnyInput = config != nil ||
                          background != nil ||
                          output != nil ||
                          center != nil ||
                          !label.isEmpty ||
                          kitchenSink ||
                          random ||
                          dumpConfig

        if !hasAnyInput {
            throw CleanExit.helpRequest(self)
        }

        // Handle --kitchen-sink flag: generate demo using all features
        if kitchenSink {
            let kitchenSinkConfig = KitchenSinkGenerator.generate()

            if dumpConfig {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(kitchenSinkConfig)
                print(String(data: data, encoding: .utf8)!)
                return
            }

            let labels = try (kitchenSinkConfig.labels ?? []).map { try $0.toIconLabel() }
            let centerContent = kitchenSinkConfig.center?.toCenterContent()
            let resolvedOutput = output ?? kitchenSinkConfig.output

            let cgImage = try await MainActor.run {
                try renderSquircle(
                    background: Background(kitchenSinkConfig.background),
                    size: kitchenSinkConfig.size,
                    cornerStyle: kitchenSinkConfig.cornerStyle,
                    cornerRadiusRatio: kitchenSinkConfig.cornerRadius,
                    labels: labels,
                    centerContent: centerContent
                )
            }

            let url = URL(fileURLWithPath: resolvedOutput)
            try savePNG(cgImage: cgImage, to: url)
            print("Generated kitchen sink demo icon at \(resolvedOutput)")
            print("  Features: gradient background, rotated center content, multiple label types")
            return
        }

        // Handle --random flag: generate random config
        if random {
            let randomConfig = RandomConfigGenerator.generate()

            if dumpConfig {
                // Just output the random config as JSON
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(randomConfig)
                print(String(data: data, encoding: .utf8)!)
                return
            }

            // Generate image from random config
            let labels = try (randomConfig.labels ?? []).map { try $0.toIconLabel() }
            let centerContent = randomConfig.center?.toCenterContent()
            let resolvedOutput = output ?? randomConfig.output

            let isAppIconSet = resolvedOutput.hasSuffix(".appiconset")

            if isAppIconSet {
                let iconPlatform = randomConfig.platform ?? .ios
                try await MainActor.run {
                    try AppIconSetGenerator.generate(
                        at: resolvedOutput,
                        platform: iconPlatform,
                        background: Background(randomConfig.background),
                        cornerStyle: randomConfig.cornerStyle,
                        cornerRadiusRatio: randomConfig.cornerRadius,
                        labels: labels,
                        centerContent: centerContent
                    )
                }
                print("Generated random \(iconPlatform.rawValue) app icon set at \(resolvedOutput)")
            } else {
                let cgImage = try await MainActor.run {
                    try renderSquircle(
                        background: Background(randomConfig.background),
                        size: randomConfig.size,
                        cornerStyle: randomConfig.cornerStyle,
                        cornerRadiusRatio: randomConfig.cornerRadius,
                        labels: labels,
                        centerContent: centerContent
                    )
                }

                let url = URL(fileURLWithPath: resolvedOutput)
                try savePNG(cgImage: cgImage, to: url)
                print("Generated random \(randomConfig.size)x\(randomConfig.size) icon at \(resolvedOutput)")
            }
            return
        }

        // Load config file if specified
        let fileConfig: IconConfiguration?
        if let configPath = config {
            fileConfig = try IconConfiguration.load(from: configPath)
        } else {
            fileConfig = nil
        }

        // Resolve values: CLI > config > defaults
        let resolvedBackground = Background(background ?? fileConfig?.background ?? "white")
        let resolvedOutput = output ?? fileConfig?.output ?? "icon.png"
        let resolvedSize = size ?? fileConfig?.size ?? 1024
        let resolvedCornerStyle = cornerStyle ?? fileConfig?.cornerStyle ?? .squircle
        let resolvedCornerRadius = cornerRadius ?? fileConfig?.cornerRadius ?? 0.2237
        let resolvedPlatform = platform ?? fileConfig?.platform

        // Merge labels: CLI labels + config labels
        var labels = label.map(\.label)
        if let configLabels = fileConfig?.labels {
            for labelConfig in configLabels {
                labels.append(try labelConfig.toIconLabel())
            }
        }

        // Resolve center content: CLI > config, with CLI options overriding config values
        let centerContent: CenterContent?
        if let centerString = center {
            // CLI --center specified: use it with CLI overrides, falling back to config values
            centerContent = CenterContent(
                contentString: centerString,
                color: CSSColor(centerColor ?? fileConfig?.center?.color ?? "black"),
                sizeRatio: centerSize ?? fileConfig?.center?.size ?? 0.5,
                alignment: centerAlign ?? fileConfig?.center?.alignment ?? .typographic,
                anchor: centerAnchor ?? fileConfig?.center?.anchor ?? .center,
                yOffset: centerYOffset ?? fileConfig?.center?.yOffset ?? 0,
                rotation: centerRotation ?? fileConfig?.center?.rotation ?? 0
            )
        } else if let configCenter = fileConfig?.center {
            // No CLI --center, but config has center: use config with CLI overrides
            centerContent = CenterContent(
                contentString: configCenter.content,
                color: CSSColor(centerColor ?? configCenter.color ?? "black"),
                sizeRatio: centerSize ?? configCenter.size ?? 0.5,
                alignment: centerAlign ?? configCenter.alignment ?? .typographic,
                anchor: centerAnchor ?? configCenter.anchor ?? .center,
                yOffset: centerYOffset ?? configCenter.yOffset ?? 0,
                rotation: centerRotation ?? configCenter.rotation ?? 0
            )
        } else {
            centerContent = nil
        }

        // If --dump-config, output JSON and exit without generating image
        if dumpConfig {
            let resolvedConfig = ResolvedConfiguration(
                background: resolvedBackground.rawValue,
                output: resolvedOutput,
                size: resolvedSize,
                cornerStyle: resolvedCornerStyle,
                cornerRadius: resolvedCornerRadius,
                platform: resolvedPlatform,
                labels: labels.map { LabelConfiguration(from: $0) },
                center: centerContent.map { CenterConfiguration(from: $0) }
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(resolvedConfig)
            print(String(data: data, encoding: .utf8)!)
            return
        }

        // Check output format
        let isAppIconSet = resolvedOutput.hasSuffix(".appiconset")
        let isSVG = resolvedOutput.lowercased().hasSuffix(".svg")

        if isSVG {
            // SVG output
            let svg = await MainActor.run {
                renderSVG(
                    background: resolvedBackground,
                    size: resolvedSize,
                    cornerStyle: resolvedCornerStyle,
                    cornerRadiusRatio: resolvedCornerRadius,
                    labels: labels,
                    centerContent: centerContent,
                    fontFamily: svgFont
                )
            }

            let url = URL(fileURLWithPath: resolvedOutput)
            try svg.write(to: url, atomically: true, encoding: .utf8)

            print("Generated \(resolvedSize)x\(resolvedSize) SVG icon at \(resolvedOutput)")
            if !labels.isEmpty {
                print("  with \(labels.count) label(s)")
            }
            if centerContent != nil {
                print("  with center content")
            }
        } else if isAppIconSet {
            let iconPlatform = resolvedPlatform ?? .ios
            try await MainActor.run {
                try AppIconSetGenerator.generate(
                    at: resolvedOutput,
                    platform: iconPlatform,
                    background: resolvedBackground,
                    cornerStyle: resolvedCornerStyle,
                    cornerRadiusRatio: resolvedCornerRadius,
                    labels: labels,
                    centerContent: centerContent
                )
            }

            let specs = AppIconSetGenerator.specs(for: iconPlatform)
            let uniqueSizes = Set(specs.map(\.pixelSize)).sorted()
            print("Generated \(iconPlatform.rawValue) app icon set at \(resolvedOutput)")
            print("  sizes: \(uniqueSizes.map { "\($0)px" }.joined(separator: ", "))")
            if !labels.isEmpty {
                print("  with \(labels.count) label(s)")
            }
            if centerContent != nil {
                print("  with center content")
            }
        } else {
            let cgImage = try await MainActor.run {
                try renderSquircle(
                    background: resolvedBackground,
                    size: resolvedSize,
                    cornerStyle: resolvedCornerStyle,
                    cornerRadiusRatio: resolvedCornerRadius,
                    labels: labels,
                    centerContent: centerContent
                )
            }

            let url = URL(fileURLWithPath: resolvedOutput)
            try savePNG(cgImage: cgImage, to: url)

            print("Generated \(resolvedSize)x\(resolvedSize) squircle icon at \(resolvedOutput)")
            if !labels.isEmpty {
                print("  with \(labels.count) label(s)")
            }
            if centerContent != nil {
                print("  with center content")
            }
        }
    }

    @MainActor
    private func renderSVG(
        background: Background,
        size: Int,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?,
        fontFamily: String?
    ) -> String {
        let iconSize = CGSize(width: size, height: size)
        var renderer: SVGIconRenderer
        if let fontFamily {
            renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: cornerRadiusRatio, fontFamily: fontFamily)
        } else {
            renderer = SVGIconRenderer(size: iconSize, cornerRadiusRatio: cornerRadiusRatio)
        }

        renderIcon(
            to: &renderer,
            background: background,
            cornerStyle: cornerStyle,
            cornerRadius: cornerRadiusRatio,
            labels: labels,
            centerContent: centerContent
        )

        return renderer.render()
    }

    @MainActor
    private func renderSquircle(
        background: Background,
        size: Int,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?
    ) throws -> CGImage {
        let squircleView = SquircleView(
            background: background,
            size: CGFloat(size),
            cornerStyle: cornerStyle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: labels,
            centerContent: centerContent
        )

        let renderer = ImageRenderer(content: squircleView)
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else {
            throw RuntimeError("Failed to render image")
        }

        return cgImage
    }

    private func savePNG(cgImage: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw RuntimeError("Failed to create image destination")
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw RuntimeError("Failed to write PNG file")
        }
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
