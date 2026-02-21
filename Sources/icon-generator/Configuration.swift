import Foundation
import SwiftUI

/// JSON configuration for icon generation
struct IconConfiguration: Codable, Sendable {
    var background: String?
    var output: String?
    var size: Int?
    var cornerStyle: CornerStyle?
    var cornerRadius: Double?
    var platform: AppIconPlatform?
    var labels: [LabelConfiguration]?
    var center: CenterConfiguration?

    enum CodingKeys: String, CodingKey {
        case background
        case output
        case size
        case cornerStyle = "corner-style"
        case cornerRadius = "corner-radius"
        case platform
        case labels
        case center
    }
}

struct LabelConfiguration: Codable, Sendable {
    let position: String
    let content: String
    var backgroundColor: String?
    var foregroundColor: String?
    var rotateContent: Bool?

    enum CodingKeys: String, CodingKey {
        case position
        case content
        case backgroundColor = "background-color"
        case foregroundColor = "foreground-color"
        case rotateContent = "rotate-content"
    }

    func toIconLabel() throws -> IconLabel {
        guard let position = LabelPosition(rawValue: position) else {
            throw ConfigurationError.invalidPosition(position)
        }

        let labelContent: LabelContent
        if content.hasPrefix("sf:") {
            labelContent = .sfSymbol(String(content.dropFirst(3)))
        } else if content.hasPrefix("@") {
            labelContent = .image(URL(fileURLWithPath: String(content.dropFirst())))
        } else {
            labelContent = .text(content)
        }

        let bgColor = CSSColor(backgroundColor ?? "red")
        let fgColor = CSSColor(foregroundColor ?? "white")

        return IconLabel(
            content: labelContent,
            position: position,
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            rotateContent: rotateContent ?? true
        )
    }
}

struct CenterConfiguration: Codable, Sendable {
    let content: String
    var color: String?
    var size: Double?
    var alignment: CenterAlignment?
    var anchor: CenterAnchor?
    var yOffset: Double?

    enum CodingKeys: String, CodingKey {
        case content
        case color
        case size
        case alignment
        case anchor
        case yOffset = "y-offset"
    }

    func toCenterContent() -> CenterContent {
        let contentType: CenterContentType
        if content.hasPrefix("sf:") {
            contentType = .sfSymbol(String(content.dropFirst(3)))
        } else if content.hasPrefix("@") {
            contentType = .image(URL(fileURLWithPath: String(content.dropFirst())))
        } else {
            contentType = .text(content)
        }

        return CenterContent(
            content: contentType,
            color: CSSColor(color ?? "black"),
            sizeRatio: size ?? 0.5,
            alignment: alignment ?? .typographic,
            anchor: anchor ?? .center,
            yOffset: yOffset ?? 0
        )
    }
}

enum ConfigurationError: Error, CustomStringConvertible {
    case invalidPosition(String)
    case invalidColor(String)
    case fileNotFound(String)
    case invalidJSON(String)

    var description: String {
        switch self {
        case .invalidPosition(let pos):
            return "Invalid label position: \(pos)"
        case .invalidColor(let color):
            return "Invalid hex color: \(color)"
        case .fileNotFound(let path):
            return "Configuration file not found: \(path)"
        case .invalidJSON(let message):
            return "Invalid JSON configuration: \(message)"
        }
    }
}

extension IconConfiguration {
    static func load(from path: String) throws -> IconConfiguration {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw ConfigurationError.fileNotFound(path)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ConfigurationError.fileNotFound(path)
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(IconConfiguration.self, from: data)
        } catch let error as DecodingError {
            switch error {
            case .keyNotFound(let key, _):
                throw ConfigurationError.invalidJSON("Missing required key: \(key.stringValue)")
            case .typeMismatch(let type, let context):
                throw ConfigurationError.invalidJSON("Type mismatch for \(context.codingPath.map(\.stringValue).joined(separator: ".")): expected \(type)")
            case .valueNotFound(let type, let context):
                throw ConfigurationError.invalidJSON("Missing value for \(context.codingPath.map(\.stringValue).joined(separator: ".")): expected \(type)")
            case .dataCorrupted(let context):
                throw ConfigurationError.invalidJSON(context.debugDescription)
            @unknown default:
                throw ConfigurationError.invalidJSON(error.localizedDescription)
            }
        }
    }
}
