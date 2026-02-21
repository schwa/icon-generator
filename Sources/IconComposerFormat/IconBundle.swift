import Foundation

/// An Apple .icon bundle containing an icon document and its assets.
///
/// The bundle structure is:
/// ```
/// MyIcon.icon/
/// ├── icon.json       # The IconDocument
/// └── Assets/         # Asset files (SVG, PNG)
///     ├── icon.svg
///     └── background.png
/// ```
public struct IconBundle: Sendable {
    /// The icon document (contents of icon.json).
    public var document: IconDocument

    /// Asset files by filename.
    public var assets: [String: Data]

    /// Creates a new empty bundle.
    public init(document: IconDocument = IconDocument(), assets: [String: Data] = [:]) {
        self.document = document
        self.assets = assets
    }

    /// Writes the bundle to disk.
    ///
    /// - Parameter url: Path where the .icon bundle should be created.
    /// - Throws: `IconBundleError` if writing fails.
    public func write(to url: URL) throws {
        let fileManager = FileManager.default

        // Create bundle directory
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        // Write icon.json
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(document)
        let iconJSONURL = url.appendingPathComponent("icon.json")
        try jsonData.write(to: iconJSONURL)

        // Write assets
        if !assets.isEmpty {
            let assetsURL = url.appendingPathComponent("Assets")
            try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)

            for (filename, data) in assets {
                let assetURL = assetsURL.appendingPathComponent(filename)
                try data.write(to: assetURL)
            }
        }
    }

    /// Adds or replaces an asset.
    public mutating func setAsset(name: String, data: Data) {
        assets[name] = data
    }
}

/// Errors that can occur when working with .icon bundles.
public enum IconBundleError: Error, CustomStringConvertible {
    case writeFailed(URL, Error)

    public var description: String {
        switch self {
        case .writeFailed(let url, let error):
            return "Failed to write bundle to \(url.path): \(error)"
        }
    }
}
