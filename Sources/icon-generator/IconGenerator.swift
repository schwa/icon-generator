import IconRendering
import IconComposerFormat
import ArgumentParser
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import QuickLookThumbnailing
import AppKit

/// Extract labels and center content from a layers array
func extractLayerContent(from layers: [LayerConfiguration]) throws -> (labels: [IconLabel], center: CenterContent?) {
    var labels: [IconLabel] = []
    var center: CenterContent? = nil

    for layer in layers {
        if layer.isCenter {
            center = try layer.toCenterContent()
        } else {
            labels.append(try layer.toIconLabel())
        }
    }

    return (labels, center)
}

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
              - Icon Composer: --output MyApp.icon (Xcode 26+)

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
                "background": {"type": "linear", "colors": ["#667eea", "#764ba2"], "angle": 135},
                "output": "icon.png",
                "size": 1024,
                "corner-style": "squircle",
                "corner-radius": 0.2237,
                "layers": [
                  {"position": "center", "symbol": "swift", "color": "#FFFFFF", "size": 0.5},
                  {"position": "topRight", "text": "BETA", "background-color": "#FF0000"},
                  {"position": "pillCenter", "symbol": "star.fill", "foreground-color": "#FFD700"}
                ]
              }

            Layer positions:
              "center"   Center content (uses color, size, alignment, anchor, y-offset)
              Labels     top, bottom, left, right, topLeft, topRight, bottomLeft,
                         bottomRight, pillLeft, pillCenter, pillRight

            JSON content keys (use one per layer):
              "text": "BETA"           Plain text
              "symbol": "star.fill"    SF Symbol name
              "image": "/path/to.png"  Image file path

            Layers can be added using --layer (repeatable).

            Layer format: position:content[:key=value...]

            Positions:
              center           Center content
              Edge ribbons:    top, bottom, left, right
              Corner ribbons:  topLeft, topRight, bottomLeft, bottomRight
              Bottom pills:    pillLeft, pillCenter, pillRight

            Content:
              Text:      Just the text string (e.g., "BETA")
              Image:     Prefix with @ (e.g., "@/path/to/icon.png")
              SF Symbol: Prefix with sf: (e.g., "sf:star.fill")

            Options (key=value):
              color, fg    Foreground color
              bg           Background color (labels only)
              size         Size ratio 0.0-1.0 (center only)
              norotate     Don't rotate content (diagonal labels)

            Examples:
              icon-generator --background "#3366FF" -o icon.png
              icon-generator --background "#3366FF" -o icon.svg
              icon-generator --background "#3366FF" -o MyApp.icon
              icon-generator -o AppIcon.appiconset --platform ios --background "#FF0000"
              icon-generator --config config.json
              --layer "center:sf:swift:color=#FFFFFF:size=0.5"
              --layer "topRight:BETA:bg=#FF0000"
              --layer "topLeft:sf:star.fill:bg=#FFD700:norotate"
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

    @Option(name: .long, parsing: .upToNextOption, help: "Layer specification (repeatable)")
    var layer: [LayerSpecification] = []

    @Option(name: .long, help: "Font family for SVG text (default: system fonts)")
    var svgFont: String?

    @Flag(name: .long, help: "Output resolved configuration as JSON (no image generated)")
    var dumpConfig: Bool = false

    @Flag(name: .long, help: "Generate random icon configuration")
    var random: Bool = false

    @Flag(name: .long, help: "Generate an icon using every feature (kitchen sink demo)")
    var kitchenSink: Bool = false

    // .icon bundle specific options
    @Option(name: .long, help: "Translucency value for .icon output (0.0 to 1.0, enables visionOS glass effect)")
    var translucency: Double?

    @Option(name: .long, help: "Shadow style for .icon output: neutral or layer-color")
    var shadow: ShadowStyle?

    @Flag(name: .long, help: "Enable glass effect for center content in .icon output")
    var glass: Bool = false

    @Flag(name: .long, help: "Render PNG via Icon Composer (generates .icon internally and uses QuickLook to render)")
    var useIconComposer: Bool = false

    mutating func run() async throws {
        // If no meaningful arguments provided, show help
        let hasAnyInput = config != nil ||
                          background != nil ||
                          output != nil ||
                          !layer.isEmpty ||
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

            let (labels, centerContent) = try extractLayerContent(from: kitchenSinkConfig.layers ?? [])
            let resolvedOutput = output ?? kitchenSinkConfig.output

            let cgImage = try await MainActor.run {
                try renderSquircle(
                    background: kitchenSinkConfig.background.toBackground(),
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
            let (labels, centerContent) = try extractLayerContent(from: randomConfig.layers ?? [])
            let resolvedOutput = output ?? randomConfig.output

            let isAppIconSet = resolvedOutput.hasSuffix(".appiconset")

            if isAppIconSet {
                let iconPlatform = randomConfig.platform ?? .ios
                try await MainActor.run {
                    try AppIconSetGenerator.generate(
                        at: resolvedOutput,
                        platform: iconPlatform,
                        background: randomConfig.background.toBackground(),
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
                        background: randomConfig.background.toBackground(),
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
        let resolvedBackground: Background
        if let bgString = background {
            resolvedBackground = Background(bgString)
        } else if let bgConfig = fileConfig?.background {
            resolvedBackground = bgConfig.toBackground()
        } else {
            resolvedBackground = .white
        }
        let resolvedOutput = output ?? fileConfig?.output ?? "icon.png"
        let resolvedSize = size ?? fileConfig?.size ?? 1024
        let resolvedCornerStyle = cornerStyle ?? fileConfig?.cornerStyle ?? .squircle
        let resolvedCornerRadius = cornerRadius ?? fileConfig?.cornerRadius ?? 0.2237
        let resolvedPlatform = platform ?? fileConfig?.platform

        // Extract layers from config file
        let (configLabels, configCenter) = try extractLayerContent(from: fileConfig?.layers ?? [])

        // Extract layers from CLI
        var cliLabels: [IconLabel] = []
        var cliCenter: CenterContent? = nil
        for spec in layer {
            switch spec.content {
            case .center(let cc):
                cliCenter = cc
            case .label(let lbl):
                cliLabels.append(lbl)
            }
        }

        // Merge: CLI layers override config
        let labels = cliLabels + configLabels
        let centerContent = cliCenter ?? configCenter

        // If --dump-config, output JSON and exit without generating image
        if dumpConfig {
            var layers: [LayerConfiguration] = []
            if let cc = centerContent {
                layers.append(LayerConfiguration(from: cc))
            }
            layers.append(contentsOf: labels.map { LayerConfiguration(from: $0) })

            let resolvedConfig = ResolvedConfiguration(
                background: BackgroundConfiguration(from: resolvedBackground),
                output: resolvedOutput,
                size: resolvedSize,
                cornerStyle: resolvedCornerStyle,
                cornerRadius: resolvedCornerRadius,
                platform: resolvedPlatform,
                layers: layers.isEmpty ? nil : layers
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(resolvedConfig)
            print(String(data: data, encoding: .utf8)!)
            return
        }

        // Check output format
        let isAppIconSet = resolvedOutput.hasSuffix(".appiconset")
        let isIconBundle = resolvedOutput.hasSuffix(".icon")
        let isSVG = resolvedOutput.lowercased().hasSuffix(".svg")

        if isIconBundle {
            // Icon Composer bundle output
            let bundleOptions = IconBundleOptions(
                translucency: translucency,
                shadowStyle: shadow,
                glass: glass
            )

            try await MainActor.run {
                try IconBundleGenerator.generate(
                    at: resolvedOutput,
                    background: resolvedBackground,
                    labels: labels,
                    centerContent: centerContent,
                    size: resolvedSize,
                    options: bundleOptions
                )
            }

            print("Generated Icon Composer bundle at \(resolvedOutput)")
            if !labels.isEmpty {
                print("  with \(labels.count) label(s)")
            }
            if centerContent != nil {
                print("  with center content")
            }
            if translucency != nil {
                print("  with translucency: \(translucency!)")
            }
            if shadow != nil {
                print("  with shadow: \(shadow!.rawValue)")
            }
            if glass {
                print("  with glass effect")
            }
        } else if isSVG {
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
        } else if useIconComposer {
            // Generate via Icon Composer: create temp .icon bundle, then use QuickLook to render PNG
            let tempDir = FileManager.default.temporaryDirectory
            let tempIconPath = tempDir.appendingPathComponent(UUID().uuidString + ".icon")
            
            defer {
                try? FileManager.default.removeItem(at: tempIconPath)
            }
            
            let bundleOptions = IconBundleOptions(
                translucency: translucency,
                shadowStyle: shadow,
                glass: glass
            )
            
            try await MainActor.run {
                try IconBundleGenerator.generate(
                    at: tempIconPath.path,
                    background: resolvedBackground,
                    labels: labels,
                    centerContent: centerContent,
                    size: resolvedSize,
                    options: bundleOptions
                )
            }
            
            // Use QuickLook to render the .icon bundle to PNG
            let request = QLThumbnailGenerator.Request(
                fileAt: tempIconPath,
                size: CGSize(width: resolvedSize, height: resolvedSize),
                scale: 1.0,
                representationTypes: .all
            )
            
            let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            let cgImage = thumbnail.cgImage
            
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                throw RuntimeError("Failed to encode thumbnail as PNG")
            }
            
            let url = URL(fileURLWithPath: resolvedOutput)
            try pngData.write(to: url)
            
            print("Generated \(resolvedSize)x\(resolvedSize) icon at \(resolvedOutput)")
            print("  rendered via Icon Composer")
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
