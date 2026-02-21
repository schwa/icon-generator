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

        let bgColor: Color
        if let bg = backgroundColor {
            guard let color = Color(hex: bg) else {
                throw ConfigurationError.invalidColor(bg)
            }
            bgColor = color
        } else {
            bgColor = .red
        }

        let fgColor: Color
        if let fg = foregroundColor {
            guard let color = Color(hex: fg) else {
                throw ConfigurationError.invalidColor(fg)
            }
            fgColor = color
        } else {
            fgColor = .white
        }

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

    func toCenterContent() throws -> CenterContent {
        let contentType: CenterContentType
        if content.hasPrefix("sf:") {
            contentType = .sfSymbol(String(content.dropFirst(3)))
        } else if content.hasPrefix("@") {
            contentType = .image(URL(fileURLWithPath: String(content.dropFirst())))
        } else {
            contentType = .text(content)
        }

        let centerColor: Color
        if let colorHex = color {
            guard let c = Color(hex: colorHex) else {
                throw ConfigurationError.invalidColor(colorHex)
            }
            centerColor = c
        } else {
            centerColor = .black
        }

        return CenterContent(
            content: contentType,
            color: centerColor,
            sizeRatio: size ?? 0.5
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
