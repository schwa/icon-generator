import IconRendering
import Foundation
import SwiftUI

// MARK: - Kitchen Sink Generator

/// Generates a demo icon configuration showcasing all available features
struct KitchenSinkGenerator {
    static func generate() -> ResolvedConfiguration {
        ResolvedConfiguration(
            // Multi-stop linear gradient at an angle
            background: "linear-gradient(135deg, #667eea, #764ba2, #f093fb)",
            output: "kitchen-sink.png",
            size: 1024,
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            platform: nil,
            labels: [
                // All 4 corner ribbons
                LabelConfiguration(
                    position: "topRight",
                    text: "BETA",              // Text content
                    backgroundColor: "#FF3B30",
                    foregroundColor: "#FFFFFF",
                    rotateContent: true,       // Rotated with ribbon (default)
                    rotation: 0
                ),
                LabelConfiguration(
                    position: "topLeft",
                    symbol: "star.fill",       // SF Symbol content
                    backgroundColor: "#FFD700",
                    foregroundColor: "#000000",
                    rotateContent: false,      // Keep upright (norotate)
                    rotation: 0
                ),
                LabelConfiguration(
                    position: "bottomLeft",
                    text: "NEW",
                    backgroundColor: "#007AFF",
                    foregroundColor: "#FFFFFF",
                    rotateContent: true,
                    rotation: 0
                ),
                LabelConfiguration(
                    position: "bottomRight",
                    symbol: "bolt.fill",
                    backgroundColor: "#FF9500",
                    foregroundColor: "#FFFFFF",
                    rotateContent: false,      // Upright symbol
                    rotation: 0
                ),

                // Edge ribbons (top and bottom - left/right would overlap corners too much)
                LabelConfiguration(
                    position: "top",
                    text: "FEATURED",
                    backgroundColor: "rgba(0,0,0,0.7)",  // Semi-transparent
                    foregroundColor: "#FFFFFF",
                    rotateContent: true,
                    rotation: 0
                ),
                LabelConfiguration(
                    position: "bottom",
                    symbol: "sparkles",
                    backgroundColor: "#000000",
                    foregroundColor: "#FFD700",
                    rotateContent: true,
                    rotation: 0
                ),

                // All 3 pill positions
                LabelConfiguration(
                    position: "pillLeft",
                    text: "v2.0",
                    backgroundColor: "#FFFFFF",
                    foregroundColor: "#000000",
                    rotateContent: true,
                    rotation: 0
                ),
                LabelConfiguration(
                    position: "pillCenter",
                    symbol: "heart.fill",
                    backgroundColor: "#FF2D55",
                    foregroundColor: "#FFFFFF",
                    rotateContent: true,
                    rotation: 15               // Label rotation
                ),
                LabelConfiguration(
                    position: "pillRight",
                    symbol: "checkmark.circle.fill",
                    backgroundColor: "#34C759",
                    foregroundColor: "#FFFFFF",
                    rotateContent: true,
                    rotation: 0
                )
            ],
            center: CenterConfiguration(
                symbol: "swift",
                color: "#FFFFFF",
                size: 0.35,                    // Smaller to fit with all labels
                alignment: .typographic,
                anchor: .center,
                yOffset: 0.03,                 // Slight upward offset
                rotation: -10                  // Slight counter-clockwise rotation
            )
        )
    }
}

// MARK: - Random Configuration Generation

/// Generates a random icon configuration
struct RandomConfigGenerator {
    /// Common SF Symbols suitable for app icons
    static let sfSymbols = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill",
        "cloud.fill", "moon.fill", "sun.max.fill", "drop.fill", "snowflake",
        "swift", "apple.logo", "app.fill", "gear", "gearshape.fill",
        "house.fill", "person.fill", "bell.fill", "envelope.fill", "paperplane.fill",
        "bookmark.fill", "tag.fill", "camera.fill", "photo.fill", "music.note",
        "play.fill", "pause.fill", "forward.fill", "backward.fill", "shuffle",
        "rectangle.stack.fill", "square.grid.2x2.fill", "circle.grid.3x3.fill",
        "cpu.fill", "memorychip.fill", "network", "wifi", "antenna.radiowaves.left.and.right",
        "lock.fill", "key.fill", "shield.fill", "checkmark.seal.fill", "rosette",
        "chart.bar.fill", "chart.pie.fill", "waveform", "gauge.with.needle.fill",
        "paintbrush.fill", "pencil", "scissors", "hammer.fill", "wrench.and.screwdriver.fill",
        "folder.fill", "doc.fill", "doc.text.fill", "book.fill", "newspaper.fill",
        "graduationcap.fill", "brain.head.profile", "lightbulb.fill", "puzzlepiece.fill",
        "flag.fill", "mappin", "location.fill", "globe", "map.fill",
        "car.fill", "airplane", "tram.fill", "bicycle", "figure.walk",
        "cart.fill", "bag.fill", "creditcard.fill", "banknote.fill", "dollarsign.circle.fill",
        "phone.fill", "video.fill", "mic.fill", "speaker.wave.3.fill", "headphones",
        "gamecontroller.fill", "paintpalette.fill", "theatermasks.fill", "film.fill", "tv.fill",
        "desktopcomputer", "laptopcomputer", "iphone", "ipad", "applewatch",
        "atom", "function", "number", "textformat", "character.book.closed.fill"
    ]

    /// Vibrant colors suitable for app icon backgrounds
    static let backgroundColors = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE", "#30B0C7",
        "#007AFF", "#5856D6", "#AF52DE", "#FF2D55", "#A2845E",
        "#1C1C1E", "#2C2C2E", "#3A3A3C", "#48484A", "#636366",
        "#F05138", "#00A86B", "#FF6B6B", "#4ECDC4", "#45B7D1",
        "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
        "#BB8FCE", "#85C1E9", "#F8B500", "#00CED1", "#FF6347",
        "dodgerblue", "crimson", "darkorange", "mediumseagreen", "slateblue",
        "tomato", "steelblue", "mediumvioletred", "darkcyan", "coral"
    ]

    /// Colors suitable for center content (high contrast)
    static let centerColors = [
        "#FFFFFF", "#000000", "#FFD700", "#F0F0F0", "#1A1A1A",
        "white", "black", "gold", "ivory", "snow"
    ]

    /// Label text options
    static let labelTexts = [
        "BETA", "NEW", "PRO", "LITE", "FREE", "PLUS", "DEV", "DEBUG",
        "ALPHA", "TEST", "DEMO", "PREVIEW", "v1.0", "v2.0", "v3.0",
        "HOT", "TOP", "VIP", "AI", "ML", "AR", "XR", "2024", "2025"
    ]

    /// Generate a random hex color
    static func randomHexColor() -> String {
        let r = Int.random(in: 0...255)
        let g = Int.random(in: 0...255)
        let b = Int.random(in: 0...255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Generate a random background (solid or gradient)
    static func randomBackground() -> String {
        // 70% solid, 20% linear gradient, 10% radial/angular
        let roll = Int.random(in: 1...10)
        if roll <= 7 {
            return backgroundColors.randomElement()!
        } else if roll <= 9 {
            // Linear gradient
            let color1 = backgroundColors.randomElement()!
            let color2 = backgroundColors.randomElement()!
            let directions = ["to bottom", "to right", "to bottom right", "45deg", "135deg"]
            let direction = directions.randomElement()!
            return "linear-gradient(\(direction), \(color1), \(color2))"
        } else {
            // Radial or angular
            if Bool.random() {
                let color1 = backgroundColors.randomElement()!
                let color2 = backgroundColors.randomElement()!
                return "radial-gradient(\(color1), \(color2))"
            } else {
                let colors = (0..<Int.random(in: 3...6)).map { _ in backgroundColors.randomElement()! }
                return "angular-gradient(\(colors.joined(separator: ", ")))"
            }
        }
    }

    /// Generate a random configuration
    static func generate() -> ResolvedConfiguration {
        let background = randomBackground()
        let cornerStyle = CornerStyle.allCases.randomElement()!
        let cornerRadius = cornerStyle == .squircle ? 0.2237 : Double.random(in: 0.1...0.4)

        // Randomly decide on center content (80% chance)
        let center: CenterConfiguration?
        if Bool.random() || Bool.random() || Bool.random() || Bool.random() { // ~94% chance
            let useSymbol = Bool.random() || Bool.random() // ~75% chance of SF Symbol
            if useSymbol {
                center = CenterConfiguration(
                    symbol: sfSymbols.randomElement()!,
                    color: centerColors.randomElement()!,
                    size: Double.random(in: 0.4...0.7),
                    alignment: Bool.random() ? .visual : .typographic,
                    anchor: CenterAnchor.allCases.randomElement()!,
                    yOffset: Bool.random() ? 0 : Double.random(in: -0.1...0.1)
                )
            } else {
                // Single letter or short text
                let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                center = CenterConfiguration(
                    text: String(letters.randomElement()!),
                    color: centerColors.randomElement()!,
                    size: Double.random(in: 0.4...0.7),
                    alignment: Bool.random() ? .visual : .typographic,
                    anchor: CenterAnchor.allCases.randomElement()!,
                    yOffset: Bool.random() ? 0 : Double.random(in: -0.1...0.1)
                )
            }
        } else {
            center = nil
        }

        // Randomly add labels (50% chance, 1-2 labels)
        var labels: [LabelConfiguration] = []
        if Bool.random() {
            let labelCount = Int.random(in: 1...2)
            var usedPositions: Set<String> = []

            for _ in 0..<labelCount {
                let positions = LabelPosition.allCases.map(\.rawValue).filter { !usedPositions.contains($0) }
                guard let position = positions.randomElement() else { break }
                usedPositions.insert(position)

                let useSymbol = Bool.random() && Bool.random() // 25% chance
                let isDiagonal = ["topLeft", "topRight", "bottomLeft", "bottomRight"].contains(position)

                if useSymbol {
                    labels.append(LabelConfiguration(
                        position: position,
                        symbol: sfSymbols.prefix(20).randomElement()!,
                        backgroundColor: backgroundColors.randomElement()!,
                        foregroundColor: centerColors.randomElement()!,
                        rotateContent: isDiagonal ? Bool.random() : true
                    ))
                } else {
                    labels.append(LabelConfiguration(
                        position: position,
                        text: labelTexts.randomElement()!,
                        backgroundColor: backgroundColors.randomElement()!,
                        foregroundColor: centerColors.randomElement()!,
                        rotateContent: isDiagonal ? Bool.random() : true
                    ))
                }
            }
        }

        return ResolvedConfiguration(
            background: background,
            output: "icon.png",
            size: 1024,
            cornerStyle: cornerStyle,
            cornerRadius: cornerRadius,
            platform: nil,
            labels: labels.isEmpty ? nil : labels,
            center: center
        )
    }
}

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
    var text: String?
    var symbol: String?
    var image: String?
    var backgroundColor: String?
    var foregroundColor: String?
    var rotateContent: Bool?
    var rotation: Double?

    init(
        position: String,
        text: String? = nil,
        symbol: String? = nil,
        image: String? = nil,
        backgroundColor: String? = nil,
        foregroundColor: String? = nil,
        rotateContent: Bool? = nil,
        rotation: Double? = nil
    ) {
        self.position = position
        self.text = text
        self.symbol = symbol
        self.image = image
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.rotateContent = rotateContent
        self.rotation = rotation
    }

    enum CodingKeys: String, CodingKey {
        case position
        case text
        case symbol
        case image
        case backgroundColor = "background-color"
        case foregroundColor = "foreground-color"
        case rotateContent = "rotate-content"
        case rotation
    }

    /// Resolve the content from text/symbol/image keys
    private func resolveContent() throws -> String {
        if let text = text {
            return text
        }
        if let symbol = symbol {
            return "sf:\(symbol)"
        }
        if let image = image {
            return "@\(image)"
        }
        throw ConfigurationError.missingContent("label at position '\(position)'")
    }

    func toIconLabel() throws -> IconLabel {
        guard let labelPosition = LabelPosition(rawValue: position) else {
            throw ConfigurationError.invalidPosition(position)
        }

        let resolvedContent = try resolveContent()

        return IconLabel(
            content: parseLabelContent(resolvedContent),
            position: labelPosition,
            backgroundColor: CSSColor(backgroundColor ?? "red"),
            foregroundColor: CSSColor(foregroundColor ?? "white"),
            rotateContent: rotateContent ?? true,
            rotation: rotation ?? 0
        )
    }
}

struct CenterConfiguration: Codable, Sendable {
    var text: String?
    var symbol: String?
    var image: String?
    var color: String?
    var size: Double?
    var alignment: CenterAlignment?
    var anchor: CenterAnchor?
    var yOffset: Double?
    var rotation: Double?

    init(
        text: String? = nil,
        symbol: String? = nil,
        image: String? = nil,
        color: String? = nil,
        size: Double? = nil,
        alignment: CenterAlignment? = nil,
        anchor: CenterAnchor? = nil,
        yOffset: Double? = nil,
        rotation: Double? = nil
    ) {
        self.text = text
        self.symbol = symbol
        self.image = image
        self.color = color
        self.size = size
        self.alignment = alignment
        self.anchor = anchor
        self.yOffset = yOffset
        self.rotation = rotation
    }

    enum CodingKeys: String, CodingKey {
        case text
        case symbol
        case image
        case color
        case size
        case alignment
        case anchor
        case yOffset = "y-offset"
        case rotation
    }

    /// Resolve the content from text/symbol/image keys
    func resolveContent() throws -> String {
        if let text = text {
            return text
        }
        if let symbol = symbol {
            return "sf:\(symbol)"
        }
        if let image = image {
            return "@\(image)"
        }
        throw ConfigurationError.missingContent("center")
    }

    func toCenterContent() throws -> CenterContent {
        let resolvedContent = try resolveContent()
        return CenterContent(
            contentString: resolvedContent,
            color: CSSColor(color ?? "black"),
            sizeRatio: size ?? 0.5,
            alignment: alignment ?? .typographic,
            anchor: anchor ?? .center,
            yOffset: yOffset ?? 0,
            rotation: rotation ?? 0
        )
    }
}

// MARK: - Content Parsing Utilities

/// Parses a content string into CenterContentType
/// - "sf:symbol.name" -> .sfSymbol("symbol.name")
/// - "@/path/to/image" -> .image(URL)
/// - "text" -> .text("text")
func parseCenterContentType(_ string: String) -> CenterContentType {
    if string.hasPrefix("sf:") {
        return .sfSymbol(String(string.dropFirst(3)))
    } else if string.hasPrefix("@") {
        return .image(URL(fileURLWithPath: String(string.dropFirst())))
    } else {
        return .text(string)
    }
}

/// Parses a content string into LabelContent
/// - "sf:symbol.name" -> .sfSymbol("symbol.name")
/// - "@/path/to/image" -> .image(URL)
/// - "text" -> .text("text")
func parseLabelContent(_ string: String) -> LabelContent {
    if string.hasPrefix("sf:") {
        return .sfSymbol(String(string.dropFirst(3)))
    } else if string.hasPrefix("@") {
        return .image(URL(fileURLWithPath: String(string.dropFirst())))
    } else {
        return .text(string)
    }
}

// MARK: - Resolved Configuration (for --dump-config)

/// Fully resolved configuration with all defaults applied
struct ResolvedConfiguration: Codable, Sendable {
    let background: String
    let output: String
    let size: Int
    let cornerStyle: CornerStyle
    let cornerRadius: Double
    let platform: AppIconPlatform?
    let labels: [LabelConfiguration]?
    let center: CenterConfiguration?

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

extension LabelConfiguration {
    /// Initialize from an IconLabel (for dump-config)
    init(from label: IconLabel) {
        self.position = label.position.rawValue
        switch label.content {
        case .text(let text):
            self.text = text
        case .sfSymbol(let name):
            self.symbol = name
        case .image(let url):
            self.image = url.path
        }
        self.backgroundColor = label.backgroundColor.rawValue
        self.foregroundColor = label.foregroundColor.rawValue
        self.rotateContent = label.rotateContent
        self.rotation = label.rotation
    }
}

extension CenterConfiguration {
    /// Initialize from a CenterContent (for dump-config)
    init(from centerContent: CenterContent) {
        switch centerContent.content {
        case .text(let text):
            self.text = text
        case .sfSymbol(let name):
            self.symbol = name
        case .image(let url):
            self.image = url.path
        }
        self.color = centerContent.color.rawValue
        self.size = centerContent.sizeRatio
        self.alignment = centerContent.alignment
        self.anchor = centerContent.anchor
        self.yOffset = centerContent.yOffset
        self.rotation = centerContent.rotation
    }
}

enum ConfigurationError: Error, CustomStringConvertible {
    case invalidPosition(String)
    case invalidColor(String)
    case fileNotFound(String)
    case invalidJSON(String)
    case missingContent(String)

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
        case .missingContent(let context):
            return "Missing content for \(context): specify 'text', 'symbol', or 'image'"
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
