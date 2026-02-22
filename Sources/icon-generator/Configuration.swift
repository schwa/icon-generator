import IconRendering
import Foundation
import SwiftUI

// MARK: - Background Configuration

/// Represents a background in JSON - either a solid color string or a gradient object
enum BackgroundConfiguration: Codable, Sendable {
    case solid(String)
    case linear(LinearGradientConfiguration)
    case radial(RadialGradientConfiguration)
    case angular(AngularGradientConfiguration)

    struct LinearGradientConfiguration: Codable, Sendable {
        var colors: [String]
        var angle: Double?          // degrees, CSS-style (0 = up, 90 = right)
        var from: String?           // e.g., "top", "bottom left"
        var to: String?             // e.g., "bottom", "top right"

        enum CodingKeys: String, CodingKey {
            case colors, angle, from, to
        }
    }

    struct RadialGradientConfiguration: Codable, Sendable {
        var colors: [String]
        var center: [Double]?       // [x, y] as 0-1 ratios, default [0.5, 0.5]
        var startRadius: Double?    // as ratio of size, default 0
        var endRadius: Double?      // as ratio of size, default 0.7

        enum CodingKeys: String, CodingKey {
            case colors, center
            case startRadius = "start-radius"
            case endRadius = "end-radius"
        }
    }

    struct AngularGradientConfiguration: Codable, Sendable {
        var colors: [String]
        var center: [Double]?       // [x, y] as 0-1 ratios, default [0.5, 0.5]
        var angle: Double?          // starting angle in degrees, default 0

        enum CodingKeys: String, CodingKey {
            case colors, center, angle
        }
    }

    init(from decoder: Decoder) throws {
        // Try as string first (solid color)
        if let container = try? decoder.singleValueContainer(),
           let string = try? container.decode(String.self) {
            self = .solid(string)
            return
        }

        // Try as object with "type" field
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "linear", "linear-gradient":
            let config = try LinearGradientConfiguration(from: decoder)
            self = .linear(config)
        case "radial", "radial-gradient":
            let config = try RadialGradientConfiguration(from: decoder)
            self = .radial(config)
        case "angular", "angular-gradient", "conic", "conic-gradient":
            let config = try AngularGradientConfiguration(from: decoder)
            self = .angular(config)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown gradient type: \(type). Use 'linear', 'radial', or 'angular'."
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .solid(let color):
            var container = encoder.singleValueContainer()
            try container.encode(color)
        case .linear(let config):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("linear", forKey: .type)
            try container.encode(config.colors, forKey: .colors)
            if let angle = config.angle {
                try container.encode(angle, forKey: .angle)
            }
            if let from = config.from {
                try container.encode(from, forKey: .from)
            }
            if let to = config.to {
                try container.encode(to, forKey: .to)
            }
        case .radial(let config):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("radial", forKey: .type)
            try container.encode(config.colors, forKey: .colors)
            if let center = config.center {
                try container.encode(center, forKey: .center)
            }
            if let startRadius = config.startRadius {
                try container.encode(startRadius, forKey: .startRadius)
            }
            if let endRadius = config.endRadius {
                try container.encode(endRadius, forKey: .endRadius)
            }
        case .angular(let config):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("angular", forKey: .type)
            try container.encode(config.colors, forKey: .colors)
            if let center = config.center {
                try container.encode(center, forKey: .center)
            }
            if let angle = config.angle {
                try container.encode(angle, forKey: .angle)
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, colors, angle, from, to, center
        case startRadius = "start-radius"
        case endRadius = "end-radius"
    }

    /// Convert to Background type
    func toBackground() -> Background {
        switch self {
        case .solid(let color):
            return Background(color)

        case .linear(let config):
            let colors = config.colors.map { CSSColor($0) }

            // Determine direction
            let (startPoint, endPoint): (UnitPoint, UnitPoint)
            if let angle = config.angle {
                // CSS gradient angles: 0deg = to top, 90deg = to right
                let radians = (angle - 90) * .pi / 180
                let dx = cos(radians)
                let dy = sin(radians)
                startPoint = UnitPoint(x: 0.5 - dx * 0.5, y: 0.5 + dy * 0.5)
                endPoint = UnitPoint(x: 0.5 + dx * 0.5, y: 0.5 - dy * 0.5)
            } else if let from = config.from, let to = config.to {
                startPoint = parseUnitPoint(from) ?? .top
                endPoint = parseUnitPoint(to) ?? .bottom
            } else if let to = config.to {
                endPoint = parseUnitPoint(to) ?? .bottom
                startPoint = oppositePoint(endPoint)
            } else {
                startPoint = .top
                endPoint = .bottom
            }

            return .linearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)

        case .radial(let config):
            let colors = config.colors.map { CSSColor($0) }
            let center: UnitPoint
            if let c = config.center, c.count == 2 {
                center = UnitPoint(x: c[0], y: c[1])
            } else {
                center = .center
            }
            return .radialGradient(
                colors: colors,
                center: center,
                startRadius: config.startRadius ?? 0,
                endRadius: config.endRadius ?? 0.7
            )

        case .angular(let config):
            let colors = config.colors.map { CSSColor($0) }
            let center: UnitPoint
            if let c = config.center, c.count == 2 {
                center = UnitPoint(x: c[0], y: c[1])
            } else {
                center = .center
            }
            let angle = Angle(degrees: config.angle ?? 0)
            return .angularGradient(colors: colors, center: center, angle: angle)
        }
    }

    /// Create from Background (for dump-config)
    init(from background: Background) {
        switch background {
        case .solid(let color):
            self = .solid(color.rawValue)

        case .linearGradient(let colors, let startPoint, let endPoint):
            // Try to convert to angle or direction
            let colorStrings = colors.map(\.rawValue)
            if let angle = angleFromPoints(start: startPoint, end: endPoint) {
                self = .linear(LinearGradientConfiguration(colors: colorStrings, angle: angle))
            } else {
                let from = unitPointToString(startPoint)
                let to = unitPointToString(endPoint)
                self = .linear(LinearGradientConfiguration(colors: colorStrings, from: from, to: to))
            }

        case .radialGradient(let colors, let center, let startRadius, let endRadius):
            let colorStrings = colors.map(\.rawValue)
            var config = RadialGradientConfiguration(colors: colorStrings)
            if center != .center {
                config.center = [center.x, center.y]
            }
            if startRadius != 0 {
                config.startRadius = startRadius
            }
            if endRadius != 0.7 {
                config.endRadius = endRadius
            }
            self = .radial(config)

        case .angularGradient(let colors, let center, let angle):
            let colorStrings = colors.map(\.rawValue)
            var config = AngularGradientConfiguration(colors: colorStrings)
            if center != .center {
                config.center = [center.x, center.y]
            }
            if angle.degrees != 0 {
                config.angle = angle.degrees
            }
            self = .angular(config)
        }
    }
}

// Helper functions for BackgroundConfiguration
private func parseUnitPoint(_ string: String) -> UnitPoint? {
    switch string.lowercased().trimmingCharacters(in: .whitespaces) {
    case "top": return .top
    case "bottom": return .bottom
    case "left", "leading": return .leading
    case "right", "trailing": return .trailing
    case "center": return .center
    case "top left", "left top", "top-left": return .topLeading
    case "top right", "right top", "top-right": return .topTrailing
    case "bottom left", "left bottom", "bottom-left": return .bottomLeading
    case "bottom right", "right bottom", "bottom-right": return .bottomTrailing
    default: return nil
    }
}

private func oppositePoint(_ point: UnitPoint) -> UnitPoint {
    UnitPoint(x: 1 - point.x, y: 1 - point.y)
}

private func unitPointToString(_ point: UnitPoint) -> String {
    switch point {
    case .top: return "top"
    case .bottom: return "bottom"
    case .leading: return "left"
    case .trailing: return "right"
    case .center: return "center"
    case .topLeading: return "top-left"
    case .topTrailing: return "top-right"
    case .bottomLeading: return "bottom-left"
    case .bottomTrailing: return "bottom-right"
    default:
        // Custom point - return as coordinates
        return "[\(point.x), \(point.y)]"
    }
}

private func angleFromPoints(start: UnitPoint, end: UnitPoint) -> Double? {
    // Common angles
    if start == .top && end == .bottom { return 180 }
    if start == .bottom && end == .top { return 0 }
    if start == .leading && end == .trailing { return 90 }
    if start == .trailing && end == .leading { return 270 }
    if start == .topLeading && end == .bottomTrailing { return 135 }
    if start == .topTrailing && end == .bottomLeading { return 225 }
    if start == .bottomLeading && end == .topTrailing { return 45 }
    if start == .bottomTrailing && end == .topLeading { return 315 }
    return nil
}

// MARK: - Kitchen Sink Generator

/// Generates a demo icon configuration showcasing all available features
struct KitchenSinkGenerator {
    static func generate() -> ResolvedConfiguration {
        ResolvedConfiguration(
            // Multi-stop linear gradient at an angle
            background: .linear(BackgroundConfiguration.LinearGradientConfiguration(
                colors: ["#667eea", "#764ba2", "#f093fb"],
                angle: 135
            )),
            output: "kitchen-sink.png",
            size: 1024,
            cornerStyle: .squircle,
            cornerRadius: 0.2237,
            platform: nil,
            layers: [
                // Center content (rendered first, behind labels)
                LayerConfiguration(
                    position: "center",
                    symbol: "swift",
                    color: "#FFFFFF",
                    size: 0.35,
                    alignment: .typographic,
                    anchor: .center,
                    yOffset: 0.03
                ),
                // All 4 corner ribbons
                LayerConfiguration(
                    position: "topRight",
                    text: "BETA",
                    backgroundColor: .linear(BackgroundConfiguration.LinearGradientConfiguration(
                        colors: ["#FF3B30", "#FF9500"],
                        angle: 45
                    )),
                    foregroundColor: "#FFFFFF",
                    rotateContent: true
                ),
                LayerConfiguration(
                    position: "topLeft",
                    symbol: "star.fill",
                    backgroundColor: .solid("#FFD700"),
                    foregroundColor: "#000000",
                    rotateContent: false
                ),
                LayerConfiguration(
                    position: "bottomLeft",
                    text: "NEW",
                    backgroundColor: .solid("#007AFF"),
                    foregroundColor: "#FFFFFF"
                ),
                LayerConfiguration(
                    position: "bottomRight",
                    symbol: "bolt.fill",
                    backgroundColor: .solid("#FF9500"),
                    foregroundColor: "#FFFFFF",
                    rotateContent: false
                ),
                // Edge ribbons
                LayerConfiguration(
                    position: "top",
                    text: "FEATURED",
                    backgroundColor: .solid("rgba(0,0,0,0.7)"),
                    foregroundColor: "#FFFFFF"
                ),
                LayerConfiguration(
                    position: "bottom",
                    symbol: "sparkles",
                    backgroundColor: .solid("#000000"),
                    foregroundColor: "#FFD700"
                ),
                // All 3 pill positions
                LayerConfiguration(
                    position: "pillLeft",
                    text: "v2.0",
                    backgroundColor: .solid("#FFFFFF"),
                    foregroundColor: "#000000"
                ),
                LayerConfiguration(
                    position: "pillCenter",
                    symbol: "heart.fill",
                    backgroundColor: .solid("#FF2D55"),
                    foregroundColor: "#FFFFFF",
                    rotation: 15
                ),
                LayerConfiguration(
                    position: "pillRight",
                    symbol: "checkmark.circle.fill",
                    backgroundColor: .solid("#34C759"),
                    foregroundColor: "#FFFFFF"
                )
            ]
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
    static func randomBackground() -> BackgroundConfiguration {
        // 70% solid, 20% linear gradient, 10% radial/angular
        let roll = Int.random(in: 1...10)
        if roll <= 7 {
            return .solid(backgroundColors.randomElement()!)
        } else if roll <= 9 {
            // Linear gradient
            let color1 = backgroundColors.randomElement()!
            let color2 = backgroundColors.randomElement()!
            let angles: [Double] = [0, 45, 90, 135, 180]
            let angle = angles.randomElement()!
            return .linear(BackgroundConfiguration.LinearGradientConfiguration(
                colors: [color1, color2],
                angle: angle
            ))
        } else {
            // Radial or angular
            if Bool.random() {
                let color1 = backgroundColors.randomElement()!
                let color2 = backgroundColors.randomElement()!
                return .radial(BackgroundConfiguration.RadialGradientConfiguration(
                    colors: [color1, color2]
                ))
            } else {
                let colors = (0..<Int.random(in: 3...6)).map { _ in backgroundColors.randomElement()! }
                return .angular(BackgroundConfiguration.AngularGradientConfiguration(
                    colors: colors
                ))
            }
        }
    }

    /// Generate a random configuration
    static func generate() -> ResolvedConfiguration {
        let background = randomBackground()
        let cornerStyle = CornerStyle.allCases.randomElement()!
        let cornerRadius = cornerStyle == .squircle ? 0.2237 : Double.random(in: 0.1...0.4)

        var layers: [LayerConfiguration] = []

        // Randomly add center content (94% chance)
        if Bool.random() || Bool.random() || Bool.random() || Bool.random() {
            let useSymbol = Bool.random() || Bool.random() // ~75% chance of SF Symbol
            if useSymbol {
                layers.append(LayerConfiguration(
                    position: "center",
                    symbol: sfSymbols.randomElement()!,
                    color: centerColors.randomElement()!,
                    size: Double.random(in: 0.4...0.7),
                    alignment: Bool.random() ? .visual : .typographic,
                    anchor: CenterAnchor.allCases.randomElement()!,
                    yOffset: Bool.random() ? 0 : Double.random(in: -0.1...0.1)
                ))
            } else {
                let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                layers.append(LayerConfiguration(
                    position: "center",
                    text: String(letters.randomElement()!),
                    color: centerColors.randomElement()!,
                    size: Double.random(in: 0.4...0.7),
                    alignment: Bool.random() ? .visual : .typographic,
                    anchor: CenterAnchor.allCases.randomElement()!,
                    yOffset: Bool.random() ? 0 : Double.random(in: -0.1...0.1)
                ))
            }
        }

        // Randomly add labels (50% chance, 1-2 labels)
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
                    layers.append(LayerConfiguration(
                        position: position,
                        symbol: sfSymbols.prefix(20).randomElement()!,
                        backgroundColor: .solid(backgroundColors.randomElement()!),
                        foregroundColor: centerColors.randomElement()!,
                        rotateContent: isDiagonal ? Bool.random() : true
                    ))
                } else {
                    layers.append(LayerConfiguration(
                        position: position,
                        text: labelTexts.randomElement()!,
                        backgroundColor: .solid(backgroundColors.randomElement()!),
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
            layers: layers.isEmpty ? nil : layers
        )
    }
}

/// JSON configuration for icon generation
struct IconConfiguration: Codable, Sendable {
    var background: BackgroundConfiguration?
    var output: String?
    var size: Int?
    var cornerStyle: CornerStyle?
    var cornerRadius: Double?
    var platform: AppIconPlatform?
    var layers: [LayerConfiguration]?

    enum CodingKeys: String, CodingKey {
        case background
        case output
        case size
        case cornerStyle = "corner-style"
        case cornerRadius = "corner-radius"
        case platform
        case layers
    }
}

/// A layer in the icon - either a label or center content
struct LayerConfiguration: Codable, Sendable {
    // Position determines the layer type:
    // - "center" = center content
    // - any label position = label
    var position: String

    // Content (one of these)
    var text: String?
    var symbol: String?
    var image: String?

    // Label-specific properties
    var backgroundColor: BackgroundConfiguration?
    var foregroundColor: String?
    var rotateContent: Bool?
    var rotation: Double?

    // Center-specific properties
    var color: String?
    var size: Double?
    var alignment: CenterAlignment?
    var anchor: CenterAnchor?
    var yOffset: Double?

    enum CodingKeys: String, CodingKey {
        case position
        case text, symbol, image
        case backgroundColor = "background-color"
        case foregroundColor = "foreground-color"
        case rotateContent = "rotate-content"
        case rotation
        case color, size, alignment, anchor
        case yOffset = "y-offset"
    }

    /// Check if this is a center layer
    var isCenter: Bool {
        position.lowercased() == "center"
    }

    /// Resolve content string from text/symbol/image
    func resolveContent() throws -> String {
        if let text = text { return text }
        if let symbol = symbol { return "sf:\(symbol)" }
        if let image = image { return "@\(image)" }
        throw ConfigurationError.missingContent("layer at position '\(position)'")
    }

    /// Convert to IconLabel (for label positions)
    func toIconLabel() throws -> IconLabel {
        guard let labelPosition = LabelPosition(rawValue: position) else {
            throw ConfigurationError.invalidPosition(position)
        }
        let resolvedContent = try resolveContent()
        let bgColor = backgroundColor?.toBackground() ?? Background("red")

        return IconLabel(
            content: parseLabelContent(resolvedContent),
            position: labelPosition,
            backgroundColor: bgColor,
            foregroundColor: CSSColor(foregroundColor ?? "white"),
            rotateContent: rotateContent ?? true,
            rotation: rotation ?? 0
        )
    }

    /// Convert to CenterContent (for center position)
    func toCenterContent() throws -> CenterContent {
        let resolvedContent = try resolveContent()
        return CenterContent(
            contentString: resolvedContent,
            color: CSSColor(color ?? foregroundColor ?? "black"),
            sizeRatio: size ?? 0.5,
            alignment: alignment ?? .typographic,
            anchor: anchor ?? .center,
            yOffset: yOffset ?? 0,
            rotation: rotation ?? 0
        )
    }

    /// Create from IconLabel
    init(from label: IconLabel) {
        self.position = label.position.rawValue
        switch label.content {
        case .text(let t): self.text = t
        case .sfSymbol(let name): self.symbol = name
        case .image(let url): self.image = url.path
        }
        self.backgroundColor = BackgroundConfiguration(from: label.backgroundColor)
        self.foregroundColor = label.foregroundColor.rawValue
        self.rotateContent = label.rotateContent
        self.rotation = label.rotation
    }

    /// Create from CenterContent
    init(from center: CenterContent) {
        self.position = "center"
        switch center.content {
        case .text(let t): self.text = t
        case .sfSymbol(let name): self.symbol = name
        case .image(let url): self.image = url.path
        }
        self.color = center.color.rawValue
        self.size = center.sizeRatio
        self.alignment = center.alignment
        self.anchor = center.anchor
        self.yOffset = center.yOffset
        self.rotation = center.rotation
    }

    /// Standard memberwise init
    init(
        position: String,
        text: String? = nil,
        symbol: String? = nil,
        image: String? = nil,
        backgroundColor: BackgroundConfiguration? = nil,
        foregroundColor: String? = nil,
        rotateContent: Bool? = nil,
        rotation: Double? = nil,
        color: String? = nil,
        size: Double? = nil,
        alignment: CenterAlignment? = nil,
        anchor: CenterAnchor? = nil,
        yOffset: Double? = nil
    ) {
        self.position = position
        self.text = text
        self.symbol = symbol
        self.image = image
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.rotateContent = rotateContent
        self.rotation = rotation
        self.color = color
        self.size = size
        self.alignment = alignment
        self.anchor = anchor
        self.yOffset = yOffset
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
    let background: BackgroundConfiguration
    let output: String
    let size: Int
    let cornerStyle: CornerStyle
    let cornerRadius: Double
    let platform: AppIconPlatform?
    let layers: [LayerConfiguration]?

    enum CodingKeys: String, CodingKey {
        case background
        case output
        case size
        case cornerStyle = "corner-style"
        case cornerRadius = "corner-radius"
        case platform
        case layers
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
        decoder.allowsJSON5 = true
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
