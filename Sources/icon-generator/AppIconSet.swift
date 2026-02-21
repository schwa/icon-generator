import ArgumentParser
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Platform target for app icon generation
enum AppIconPlatform: String, CaseIterable, Sendable, Codable, ExpressibleByArgument {
    case ios
    case macos
    case watchos
    case universal  // iOS + macOS combined
}

/// Represents a single icon size specification
struct IconSpec: Sendable {
    let size: Int          // Point size
    let scale: Int         // 1x, 2x, 3x
    let idiom: String      // "universal", "mac", "iphone", "ipad", etc.
    let platform: String?  // "ios", "macos", etc.

    var pixelSize: Int { size * scale }
    var filename: String { "\(pixelSize).png" }
    var sizeString: String { "\(size)x\(size)" }
    var scaleString: String { "\(scale)x" }
}

/// App Icon Set generator
struct AppIconSetGenerator {
    /// iOS icon specifications (single 1024x1024 icon)
    static let iosSpecs: [IconSpec] = [
        IconSpec(size: 1024, scale: 1, idiom: "universal", platform: "ios"),
    ]

    /// macOS icon specifications (multiple sizes)
    static let macosSpecs: [IconSpec] = [
        IconSpec(size: 16, scale: 1, idiom: "mac", platform: nil),
        IconSpec(size: 16, scale: 2, idiom: "mac", platform: nil),
        IconSpec(size: 32, scale: 1, idiom: "mac", platform: nil),
        IconSpec(size: 32, scale: 2, idiom: "mac", platform: nil),
        IconSpec(size: 128, scale: 1, idiom: "mac", platform: nil),
        IconSpec(size: 128, scale: 2, idiom: "mac", platform: nil),
        IconSpec(size: 256, scale: 1, idiom: "mac", platform: nil),
        IconSpec(size: 256, scale: 2, idiom: "mac", platform: nil),
        IconSpec(size: 512, scale: 1, idiom: "mac", platform: nil),
        IconSpec(size: 512, scale: 2, idiom: "mac", platform: nil),
    ]

    /// watchOS icon specifications
    static let watchosSpecs: [IconSpec] = [
        IconSpec(size: 1024, scale: 1, idiom: "universal", platform: "watchos"),
    ]

    /// Get specs for a platform
    static func specs(for platform: AppIconPlatform) -> [IconSpec] {
        switch platform {
        case .ios:
            return iosSpecs
        case .macos:
            return macosSpecs
        case .watchos:
            return watchosSpecs
        case .universal:
            return iosSpecs + macosSpecs
        }
    }

    /// Generate Contents.json for the icon set
    static func generateContentsJSON(for platform: AppIconPlatform) -> Data {
        let specs = specs(for: platform)

        // Group by pixel size to avoid duplicate filenames
        var filenameMap: [Int: String] = [:]
        var imageEntries: [[String: Any]] = []

        for spec in specs {
            // Generate unique filename if needed
            let filename: String
            if let existing = filenameMap[spec.pixelSize] {
                filename = existing
            } else {
                filename = spec.filename
                filenameMap[spec.pixelSize] = filename
            }

            var entry: [String: Any] = [
                "filename": filename,
                "idiom": spec.idiom,
                "scale": spec.scaleString,
                "size": spec.sizeString,
            ]

            if let platform = spec.platform {
                entry["platform"] = platform
            }

            imageEntries.append(entry)
        }

        let contents: [String: Any] = [
            "images": imageEntries,
            "info": [
                "author": "icon-generator",
                "version": 1,
            ],
        ]

        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    }

    /// Generate an app icon set at the specified path
    @MainActor
    static func generate(
        at outputPath: String,
        platform: AppIconPlatform,
        background: Background,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?
    ) throws {
        let specs = specs(for: platform)
        let uniqueSizes = Set(specs.map(\.pixelSize)).sorted()

        // Create the .appiconset directory
        let iconSetURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

        // Generate each unique size
        for pixelSize in uniqueSizes {
            let view = SquircleView(
                background: background,
                size: CGFloat(pixelSize),
                cornerStyle: cornerStyle,
                cornerRadiusRatio: cornerRadiusRatio,
                labels: labels,
                centerContent: centerContent
            )

            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0

            guard let cgImage = renderer.cgImage else {
                throw AppIconSetError.renderFailed(size: pixelSize)
            }

            let imageURL = iconSetURL.appendingPathComponent("\(pixelSize).png")
            try savePNG(cgImage: cgImage, to: imageURL)
        }

        // Write Contents.json
        let contentsJSON = generateContentsJSON(for: platform)
        let contentsURL = iconSetURL.appendingPathComponent("Contents.json")
        try contentsJSON.write(to: contentsURL)
    }

    private static func savePNG(cgImage: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw AppIconSetError.destinationFailed(path: url.path)
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw AppIconSetError.writeFailed(path: url.path)
        }
    }
}

enum AppIconSetError: Error, CustomStringConvertible {
    case renderFailed(size: Int)
    case destinationFailed(path: String)
    case writeFailed(path: String)

    var description: String {
        switch self {
        case .renderFailed(let size):
            return "Failed to render icon at size \(size)"
        case .destinationFailed(let path):
            return "Failed to create image destination: \(path)"
        case .writeFailed(let path):
            return "Failed to write PNG: \(path)"
        }
    }
}
