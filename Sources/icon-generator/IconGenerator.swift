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
              icon-generator -o AppIcon.appiconset --platform ios --background "#FF0000"
              icon-generator -o AppIcon.appiconset --platform macos --center "sf:swift"
              icon-generator --config config.json
              --label topRight:BETA
              --center "sf:swift" --center-color "#F05138"
            """
    )

    @Option(name: .shortAndLong, help: "Path to JSON configuration file")
    var config: String?

    @Option(name: .long, help: "Background color in hex format (e.g., #FF0000)")
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

    mutating func run() async throws {
        // Load config file if specified
        let fileConfig: IconConfiguration?
        if let configPath = config {
            fileConfig = try IconConfiguration.load(from: configPath)
        } else {
            fileConfig = nil
        }

        // Resolve values: CLI > config > defaults
        let resolvedBackground = background ?? fileConfig?.background ?? "#FFFFFF"
        let resolvedOutput = output ?? fileConfig?.output ?? "icon.png"
        let resolvedSize = size ?? fileConfig?.size ?? 1024
        let resolvedCornerStyle = cornerStyle ?? fileConfig?.cornerStyle ?? .squircle
        let resolvedCornerRadius = cornerRadius ?? fileConfig?.cornerRadius ?? 0.2237
        let resolvedPlatform = platform ?? fileConfig?.platform

        guard let color = Color(hex: resolvedBackground) else {
            throw ValidationError("Invalid hex color: \(resolvedBackground)")
        }

        // Merge labels: CLI labels + config labels
        var labels = label.map(\.label)
        if let configLabels = fileConfig?.labels {
            for labelConfig in configLabels {
                labels.append(try labelConfig.toIconLabel())
            }
        }

        // Resolve center content: CLI > config
        let centerContent: CenterContent?
        if let centerString = center {
            let resolvedCenterColor = centerColor ?? "#000000"
            let resolvedCenterSize = centerSize ?? 0.5
            guard let centerCol = Color(hex: resolvedCenterColor) else {
                throw ValidationError("Invalid center color: \(resolvedCenterColor)")
            }
            let contentType: CenterContentType
            if centerString.hasPrefix("sf:") {
                contentType = .sfSymbol(String(centerString.dropFirst(3)))
            } else if centerString.hasPrefix("@") {
                contentType = .image(URL(fileURLWithPath: String(centerString.dropFirst())))
            } else {
                contentType = .text(centerString)
            }
            centerContent = CenterContent(
                content: contentType,
                color: centerCol,
                sizeRatio: resolvedCenterSize
            )
        } else if let configCenter = fileConfig?.center {
            centerContent = try configCenter.toCenterContent()
        } else {
            centerContent = nil
        }

        // Check if output is an appiconset directory
        let isAppIconSet = resolvedOutput.hasSuffix(".appiconset")

        if isAppIconSet {
            let iconPlatform = resolvedPlatform ?? .ios
            try await MainActor.run {
                try AppIconSetGenerator.generate(
                    at: resolvedOutput,
                    platform: iconPlatform,
                    backgroundColor: color,
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
                    backgroundColor: color,
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
    private func renderSquircle(
        backgroundColor: Color,
        size: Int,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?
    ) throws -> CGImage {
        let squircleView = SquircleView(
            backgroundColor: backgroundColor,
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
