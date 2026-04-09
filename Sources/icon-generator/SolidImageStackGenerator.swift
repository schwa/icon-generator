import Foundation
import IconRendering
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Generates a visionOS `.solidimagestack` app icon with three layers (Back, Middle, Front).
///
/// Directory structure:
/// ```
/// AppIcon.solidimagestack/
/// ├── Contents.json
/// ├── Back.solidimagestacklayer/
/// │   ├── Contents.json
/// │   └── Content.imageset/
/// │       ├── Contents.json
/// │       └── back.png
/// ├── Middle.solidimagestacklayer/
/// │   ├── Contents.json
/// │   └── Content.imageset/
/// │       ├── Contents.json
/// │       └── middle.png
/// └── Front.solidimagestacklayer/
///     ├── Contents.json
///     └── Content.imageset/
///         ├── Contents.json
///         └── front.png
/// ```
///
/// Layer mapping:
/// - **Back**: Background fill only (gradient/color)
/// - **Middle**: Labels/ribbons only (transparent background)
/// - **Front**: Center content only (transparent background)
struct SolidImageStackGenerator {
    /// The three layers in a solidimagestack, ordered front-to-back for Contents.json.
    enum Layer: String, CaseIterable {
        case front = "Front"
        case middle = "Middle"
        case back = "Back"
    }

    /// Generate a `.solidimagestack` bundle at the specified path.
    ///
    /// Each layer is rendered at 1024×1024 @2x (the standard visionOS icon size).
    @MainActor
    static func generate(
        at outputPath: String,
        background: Background,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?
    ) throws {
        let pixelSize = 1024
        let rootURL = URL(fileURLWithPath: outputPath)
        let fileManager = FileManager.default

        // Create the root .solidimagestack directory
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)

        // --- Back layer: background only ---
        let backImage = try renderLayer(
            background: background,
            cornerStyle: cornerStyle,
            cornerRadiusRatio: cornerRadiusRatio,
            labels: [],
            centerContent: nil,
            size: pixelSize
        )
        try writeLayer(.back, image: backImage, under: rootURL)

        // --- Middle layer: labels only (transparent background) ---
        if !labels.isEmpty {
            let middleImage = try renderLayer(
                background: .clear,
                cornerStyle: cornerStyle,
                cornerRadiusRatio: cornerRadiusRatio,
                labels: labels,
                centerContent: nil,
                size: pixelSize
            )
            try writeLayer(.middle, image: middleImage, under: rootURL)
        } else {
            try writeEmptyLayer(.middle, under: rootURL)
        }

        // --- Front layer: center content only (transparent background) ---
        if let center = centerContent {
            let frontImage = try renderLayer(
                background: .clear,
                cornerStyle: cornerStyle,
                cornerRadiusRatio: cornerRadiusRatio,
                labels: [],
                centerContent: center,
                size: pixelSize
            )
            try writeLayer(.front, image: frontImage, under: rootURL)
        } else {
            try writeEmptyLayer(.front, under: rootURL)
        }

        // Write root Contents.json
        let rootContents = rootContentsJSON()
        try rootContents.write(to: rootURL.appendingPathComponent("Contents.json"))
    }

    // MARK: - Rendering

    /// Render a single layer to a CGImage.
    @MainActor
    private static func renderLayer(
        background: Background,
        cornerStyle: CornerStyle,
        cornerRadiusRatio: Double,
        labels: [IconLabel],
        centerContent: CenterContent?,
        size: Int
    ) throws -> CGImage {
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
            throw SolidImageStackError.renderFailed
        }
        return cgImage
    }

    // MARK: - File Structure

    /// Write a layer with an image into the solidimagestack bundle.
    private static func writeLayer(_ layer: Layer, image: CGImage, under rootURL: URL) throws {
        let layerURL = rootURL.appendingPathComponent("\(layer.rawValue).solidimagestacklayer")
        let imagesetURL = layerURL.appendingPathComponent("Content.imageset")
        try FileManager.default.createDirectory(at: imagesetURL, withIntermediateDirectories: true)

        // Write the PNG
        let imageName = "\(layer.rawValue.lowercased()).png"
        let imageURL = imagesetURL.appendingPathComponent(imageName)
        try savePNG(cgImage: image, to: imageURL)

        // Write Content.imageset/Contents.json
        let imagesetContents = imagesetContentsJSON(filename: imageName)
        try imagesetContents.write(to: imagesetURL.appendingPathComponent("Contents.json"))

        // Write layer Contents.json (empty info)
        let layerContents = layerContentsJSON()
        try layerContents.write(to: layerURL.appendingPathComponent("Contents.json"))
    }

    /// Write an empty layer (no image) into the solidimagestack bundle.
    private static func writeEmptyLayer(_ layer: Layer, under rootURL: URL) throws {
        let layerURL = rootURL.appendingPathComponent("\(layer.rawValue).solidimagestacklayer")
        let imagesetURL = layerURL.appendingPathComponent("Content.imageset")
        try FileManager.default.createDirectory(at: imagesetURL, withIntermediateDirectories: true)

        // Write Content.imageset/Contents.json with no filename
        let imagesetContents = emptyImagesetContentsJSON()
        try imagesetContents.write(to: imagesetURL.appendingPathComponent("Contents.json"))

        // Write layer Contents.json
        let layerContents = layerContentsJSON()
        try layerContents.write(to: layerURL.appendingPathComponent("Contents.json"))
    }

    // MARK: - JSON Generation

    /// Root Contents.json listing the three layers front-to-back.
    private static func rootContentsJSON() -> Data {
        let contents: [String: Any] = [
            "info": [
                "author": "icon-generator",
                "version": 1
            ],
            "layers": [
                ["filename": "Front.solidimagestacklayer"],
                ["filename": "Middle.solidimagestacklayer"],
                ["filename": "Back.solidimagestacklayer"]
            ]
        ]
        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    }

    /// Layer-level Contents.json (just info, no images).
    private static func layerContentsJSON() -> Data {
        let contents: [String: Any] = [
            "info": [
                "author": "icon-generator",
                "version": 1
            ]
        ]
        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    }

    /// Content.imageset Contents.json with a single @2x vision image.
    private static func imagesetContentsJSON(filename: String) -> Data {
        let contents: [String: Any] = [
            "images": [
                [
                    "filename": filename,
                    "idiom": "vision",
                    "scale": "2x"
                ]
            ],
            "info": [
                "author": "icon-generator",
                "version": 1
            ]
        ]
        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    }

    /// Content.imageset Contents.json with no image (empty layer).
    private static func emptyImagesetContentsJSON() -> Data {
        let contents: [String: Any] = [
            "images": [
                [
                    "idiom": "vision",
                    "scale": "2x"
                ]
            ],
            "info": [
                "author": "icon-generator",
                "version": 1
            ]
        ]
        // swiftlint:disable:next force_try
        return try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - PNG Writing

    private static func savePNG(cgImage: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw SolidImageStackError.destinationFailed(path: url.path)
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw SolidImageStackError.writeFailed(path: url.path)
        }
    }
}

enum SolidImageStackError: Error, CustomStringConvertible {
    case renderFailed
    case destinationFailed(path: String)
    case writeFailed(path: String)

    var description: String {
        switch self {
        case .renderFailed:
            return "Failed to render solidimagestack layer"
        case .destinationFailed(let path):
            return "Failed to create image destination: \(path)"
        case .writeFailed(let path):
            return "Failed to write PNG: \(path)"
        }
    }
}
