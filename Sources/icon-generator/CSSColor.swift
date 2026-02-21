import ArgumentParser
import CoreGraphics
import SwiftUI

/// A color specified as a CSS-style string.
///
/// Supported formats:
/// - Hex: `#RGB`, `#RRGGBB`, `#RRGGBBAA`
/// - RGB: `rgb(255, 128, 0)`, `rgb(255 128 0)`
/// - RGBA: `rgba(255, 128, 0, 0.5)`, `rgba(255 128 0 / 0.5)`
/// - RGB percentages: `rgb(100%, 50%, 0%)`
/// - Named colors: `red`, `blue`, `steelblue`, etc.
struct CSSColor: Sendable, Hashable, CustomStringConvertible {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String { rawValue }

    /// Parse and return as SwiftUI Color, or nil if invalid
    func color() -> Color? {
        guard let components = parse() else { return nil }
        return Color(red: components.red, green: components.green, blue: components.blue, opacity: components.alpha)
    }

    /// Parse and return as CGColor, or nil if invalid
    func cgColor() -> CGColor? {
        guard let components = parse() else { return nil }
        return CGColor(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
    }

    /// Parsed RGBA components (0.0-1.0)
    struct Components: Sendable, Hashable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
    }

    /// Parse the color string into components
    func parse() -> Components? {
        let input = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Try hex format
        if input.hasPrefix("#") {
            return parseHex(input)
        }

        // Try rgb()/rgba() format
        if input.hasPrefix("rgb") {
            return parseRGB(input)
        }

        // Try named color
        if let rgb = Self.cssColors[input] {
            return Components(
                red: Double((rgb >> 16) & 0xFF) / 255.0,
                green: Double((rgb >> 8) & 0xFF) / 255.0,
                blue: Double(rgb & 0xFF) / 255.0,
                alpha: input == "transparent" ? 0.0 : 1.0
            )
        }

        // Try as hex without # prefix
        return parseHex("#" + input)
    }

    private func parseHex(_ hex: String) -> Components? {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }

        let length = hexString.count
        guard length == 3 || length == 6 || length == 8 else {
            return nil
        }

        // Expand shorthand #RGB to #RRGGBB
        if length == 3 {
            hexString = hexString.map { "\($0)\($0)" }.joined()
        }

        guard let hexValue = UInt64(hexString.prefix(6), radix: 16) else {
            return nil
        }

        let red = Double((hexValue >> 16) & 0xFF) / 255.0
        let green = Double((hexValue >> 8) & 0xFF) / 255.0
        let blue = Double(hexValue & 0xFF) / 255.0

        var alpha = 1.0
        if hexString.count == 8 {
            let alphaString = String(hexString.suffix(2))
            if let alphaValue = UInt64(alphaString, radix: 16) {
                alpha = Double(alphaValue) / 255.0
            }
        }

        return Components(red: red, green: green, blue: blue, alpha: alpha)
    }

    private func parseRGB(_ input: String) -> Components? {
        // Extract content between parentheses
        guard let start = input.firstIndex(of: "("),
              let end = input.lastIndex(of: ")") else {
            return nil
        }

        let content = String(input[input.index(after: start)..<end])

        // Handle modern syntax: rgb(255 128 0 / 0.5) or legacy: rgb(255, 128, 0)
        let hasSlash = content.contains("/")
        let parts: [String]

        if hasSlash {
            let slashParts = content.split(separator: "/").map { String($0).trimmingCharacters(in: .whitespaces) }
            guard slashParts.count == 2 else { return nil }

            let colorPart = slashParts[0]
            let alphaPart = slashParts[1]

            let colorValues = colorPart
                .replacingOccurrences(of: ",", with: " ")
                .split(whereSeparator: { $0.isWhitespace })
                .map { String($0) }

            parts = colorValues + [alphaPart]
        } else {
            parts = content
                .replacingOccurrences(of: ",", with: " ")
                .split(whereSeparator: { $0.isWhitespace })
                .map { String($0) }
        }

        guard parts.count >= 3 else { return nil }

        func parseValue(_ str: String, max: Double = 255.0) -> Double? {
            if str.hasSuffix("%") {
                guard let pct = Double(str.dropLast()) else { return nil }
                return pct / 100.0
            } else {
                guard let val = Double(str) else { return nil }
                return val / max
            }
        }

        guard let red = parseValue(parts[0]),
              let green = parseValue(parts[1]),
              let blue = parseValue(parts[2]) else {
            return nil
        }

        var alpha = 1.0
        if parts.count >= 4 {
            let alphaStr = parts[3]
            if alphaStr.hasSuffix("%") {
                guard let pct = Double(alphaStr.dropLast()) else { return nil }
                alpha = pct / 100.0
            } else {
                guard let val = Double(alphaStr) else { return nil }
                alpha = val > 1 ? val / 255.0 : val
            }
        }

        return Components(
            red: min(1, max(0, red)),
            green: min(1, max(0, green)),
            blue: min(1, max(0, blue)),
            alpha: min(1, max(0, alpha))
        )
    }

    // CSS named colors
    private static let cssColors: [String: UInt32] = [
        // Basic colors
        "black": 0x000000,
        "white": 0xFFFFFF,
        "red": 0xFF0000,
        "green": 0x008000,
        "blue": 0x0000FF,
        "yellow": 0xFFFF00,
        "cyan": 0x00FFFF,
        "magenta": 0xFF00FF,
        "aqua": 0x00FFFF,
        "fuchsia": 0xFF00FF,
        "lime": 0x00FF00,
        "maroon": 0x800000,
        "navy": 0x000080,
        "olive": 0x808000,
        "purple": 0x800080,
        "teal": 0x008080,
        "silver": 0xC0C0C0,
        "gray": 0x808080,
        "grey": 0x808080,

        // Extended colors
        "aliceblue": 0xF0F8FF,
        "antiquewhite": 0xFAEBD7,
        "aquamarine": 0x7FFFD4,
        "azure": 0xF0FFFF,
        "beige": 0xF5F5DC,
        "bisque": 0xFFE4C4,
        "blanchedalmond": 0xFFEBCD,
        "blueviolet": 0x8A2BE2,
        "brown": 0xA52A2A,
        "burlywood": 0xDEB887,
        "cadetblue": 0x5F9EA0,
        "chartreuse": 0x7FFF00,
        "chocolate": 0xD2691E,
        "coral": 0xFF7F50,
        "cornflowerblue": 0x6495ED,
        "cornsilk": 0xFFF8DC,
        "crimson": 0xDC143C,
        "darkblue": 0x00008B,
        "darkcyan": 0x008B8B,
        "darkgoldenrod": 0xB8860B,
        "darkgray": 0xA9A9A9,
        "darkgrey": 0xA9A9A9,
        "darkgreen": 0x006400,
        "darkkhaki": 0xBDB76B,
        "darkmagenta": 0x8B008B,
        "darkolivegreen": 0x556B2F,
        "darkorange": 0xFF8C00,
        "darkorchid": 0x9932CC,
        "darkred": 0x8B0000,
        "darksalmon": 0xE9967A,
        "darkseagreen": 0x8FBC8F,
        "darkslateblue": 0x483D8B,
        "darkslategray": 0x2F4F4F,
        "darkslategrey": 0x2F4F4F,
        "darkturquoise": 0x00CED1,
        "darkviolet": 0x9400D3,
        "deeppink": 0xFF1493,
        "deepskyblue": 0x00BFFF,
        "dimgray": 0x696969,
        "dimgrey": 0x696969,
        "dodgerblue": 0x1E90FF,
        "firebrick": 0xB22222,
        "floralwhite": 0xFFFAF0,
        "forestgreen": 0x228B22,
        "gainsboro": 0xDCDCDC,
        "ghostwhite": 0xF8F8FF,
        "gold": 0xFFD700,
        "goldenrod": 0xDAA520,
        "greenyellow": 0xADFF2F,
        "honeydew": 0xF0FFF0,
        "hotpink": 0xFF69B4,
        "indianred": 0xCD5C5C,
        "indigo": 0x4B0082,
        "ivory": 0xFFFFF0,
        "khaki": 0xF0E68C,
        "lavender": 0xE6E6FA,
        "lavenderblush": 0xFFF0F5,
        "lawngreen": 0x7CFC00,
        "lemonchiffon": 0xFFFACD,
        "lightblue": 0xADD8E6,
        "lightcoral": 0xF08080,
        "lightcyan": 0xE0FFFF,
        "lightgoldenrodyellow": 0xFAFAD2,
        "lightgray": 0xD3D3D3,
        "lightgrey": 0xD3D3D3,
        "lightgreen": 0x90EE90,
        "lightpink": 0xFFB6C1,
        "lightsalmon": 0xFFA07A,
        "lightseagreen": 0x20B2AA,
        "lightskyblue": 0x87CEFA,
        "lightslategray": 0x778899,
        "lightslategrey": 0x778899,
        "lightsteelblue": 0xB0C4DE,
        "lightyellow": 0xFFFFE0,
        "limegreen": 0x32CD32,
        "linen": 0xFAF0E6,
        "mediumaquamarine": 0x66CDAA,
        "mediumblue": 0x0000CD,
        "mediumorchid": 0xBA55D3,
        "mediumpurple": 0x9370DB,
        "mediumseagreen": 0x3CB371,
        "mediumslateblue": 0x7B68EE,
        "mediumspringgreen": 0x00FA9A,
        "mediumturquoise": 0x48D1CC,
        "mediumvioletred": 0xC71585,
        "midnightblue": 0x191970,
        "mintcream": 0xF5FFFA,
        "mistyrose": 0xFFE4E1,
        "moccasin": 0xFFE4B5,
        "navajowhite": 0xFFDEAD,
        "oldlace": 0xFDF5E6,
        "olivedrab": 0x6B8E23,
        "orange": 0xFFA500,
        "orangered": 0xFF4500,
        "orchid": 0xDA70D6,
        "palegoldenrod": 0xEEE8AA,
        "palegreen": 0x98FB98,
        "paleturquoise": 0xAFEEEE,
        "palevioletred": 0xDB7093,
        "papayawhip": 0xFFEFD5,
        "peachpuff": 0xFFDAB9,
        "peru": 0xCD853F,
        "pink": 0xFFC0CB,
        "plum": 0xDDA0DD,
        "powderblue": 0xB0E0E6,
        "rebeccapurple": 0x663399,
        "rosybrown": 0xBC8F8F,
        "royalblue": 0x4169E1,
        "saddlebrown": 0x8B4513,
        "salmon": 0xFA8072,
        "sandybrown": 0xF4A460,
        "seagreen": 0x2E8B57,
        "seashell": 0xFFF5EE,
        "sienna": 0xA0522D,
        "skyblue": 0x87CEEB,
        "slateblue": 0x6A5ACD,
        "slategray": 0x708090,
        "slategrey": 0x708090,
        "snow": 0xFFFAFA,
        "springgreen": 0x00FF7F,
        "steelblue": 0x4682B4,
        "tan": 0xD2B48C,
        "thistle": 0xD8BFD8,
        "tomato": 0xFF6347,
        "turquoise": 0x40E0D0,
        "violet": 0xEE82EE,
        "wheat": 0xF5DEB3,
        "whitesmoke": 0xF5F5F5,
        "yellowgreen": 0x9ACD32,
        "transparent": 0x000000,
    ]
}

// MARK: - ArgumentParser conformance

extension CSSColor: ExpressibleByArgument {
    init?(argument: String) {
        self.init(argument)
    }
}

// MARK: - Codable conformance

extension CSSColor: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Default colors

extension CSSColor {
    static let white = CSSColor("white")
    static let black = CSSColor("black")
    static let red = CSSColor("red")
    static let blue = CSSColor("blue")
    static let green = CSSColor("green")
    static let yellow = CSSColor("yellow")
    static let orange = CSSColor("orange")
    static let purple = CSSColor("purple")
    static let pink = CSSColor("pink")
    static let gray = CSSColor("gray")
    static let clear = CSSColor("transparent")
}
