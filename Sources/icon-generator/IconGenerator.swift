import ArgumentParser
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@main
struct IconGenerator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "icon-generator",
        abstract: "Generate a squircle icon as a PNG image",
        discussion: """
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
              --label topRight:BETA
              --label bottom:v1.0:#0000FF
              --label pillCenter:NEW:#FF0000:#000000
              --label topLeft:@/path/to/image.png:#00FF00
              --label topRight:sf:star.fill:#FFD700:#FFFFFF
              --center "A" --center-color "#FFFFFF" --center-size 0.6
              --center "sf:swift" --center-color "#F05138"
            """
    )

    @Option(name: .long, help: "Background color in hex format (e.g., #FF0000)")
    var background: String = "#FFFFFF"

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "icon.png"

    @Option(name: .long, help: "Image size in pixels")
    var size: Int = 1024

    @Option(name: .long, help: "Corner radius ratio (0.0 to 0.5)")
    var cornerRadius: Double = 0.2237

    @Option(name: .long, parsing: .upToNextOption, help: "Label specification (repeatable)")
    var label: [LabelSpecification] = []

    @Option(name: .long, help: "Center content (text, @image path, or sf:symbol)")
    var center: String?

    @Option(name: .long, help: "Center content color in hex format")
    var centerColor: String = "#000000"

    @Option(name: .long, help: "Center content size ratio (0.0 to 1.0)")
    var centerSize: Double = 0.5

    mutating func run() async throws {
        guard let color = Color(hex: background) else {
            throw ValidationError("Invalid hex color: \(background)")
        }

        let labels = label.map(\.label)

        let centerContent: CenterContent?
        if let centerString = center {
            guard let centerCol = Color(hex: centerColor) else {
                throw ValidationError("Invalid center color: \(centerColor)")
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
                sizeRatio: centerSize
            )
        } else {
            centerContent = nil
        }

        let cgImage = try await MainActor.run {
            try renderSquircle(
                backgroundColor: color,
                size: size,
                cornerRadiusRatio: cornerRadius,
                labels: labels,
                centerContent: centerContent
            )
        }

        let url = URL(fileURLWithPath: output)
        try savePNG(cgImage: cgImage, to: url)

        print("Generated \(size)x\(size) squircle icon at \(output)")
        if !labels.isEmpty {
            print("  with \(labels.count) label(s)")
        }
        if centerContent != nil {
            print("  with center content")
        }
    }

    @MainActor
    private func renderSquircle(
        backgroundColor: Color,
        size: Int,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?
    ) throws -> CGImage {
        let squircleView = SquircleView(
            backgroundColor: backgroundColor,
            size: CGFloat(size),
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
