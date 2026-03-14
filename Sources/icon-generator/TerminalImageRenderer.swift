import Foundation
import AppKit

/// Renders an image inline in the terminal.
///
/// Detects the terminal and uses the appropriate protocol:
/// - Kitty graphics protocol (Ghostty, Kitty, WezTerm)
/// - iTerm2 inline image protocol (iTerm2, WezTerm)
enum TerminalImageRenderer {

    enum ImageProtocol {
        case kitty
        case iterm2
    }

    static func render(url: URL, scale: Double? = nil) throws {
        let data: Data
        if let scale, scale != 1.0 {
            data = try scaleImage(url: url, scale: scale)
        } else {
            data = try Data(contentsOf: url)
        }
        switch detectImageProtocol() {
        case .kitty:
            renderKitty(data: data)
        case .iterm2:
            renderITerm2(data: data, url: url)
        }
    }

    // MARK: - Protocol detection

    private static func detectImageProtocol() -> ImageProtocol {
        let env = ProcessInfo.processInfo.environment
        let termProgram = env["TERM_PROGRAM"] ?? ""
        let term = env["TERM"] ?? ""
        let kittyPid = env["KITTY_WINDOW_ID"]

        if kittyPid != nil || term.contains("kitty") || term.contains("ghostty") || termProgram.lowercased().contains("ghostty") {
            return .kitty
        }
        return .iterm2
    }

    // MARK: - Kitty graphics protocol

    /// Sends PNG data using the Kitty graphics protocol (APC sequences).
    /// Reference: https://sw.kovidgoyal.net/kitty/graphics-protocol/
    private static func renderKitty(data: Data) {
        let base64 = data.base64EncodedString()
        let chunkSize = 4096
        var offset = base64.startIndex
        var isFirst = true

        var output = Data()

        while offset < base64.endIndex {
            let end = base64.index(offset, offsetBy: chunkSize, limitedBy: base64.endIndex) ?? base64.endIndex
            let chunk = String(base64[offset..<end])
            let more = end < base64.endIndex ? 1 : 0

            let header: String
            if isFirst {
                // a=T: transmit+display, f=100: PNG format, m=more
                header = "a=T,f=100,m=\(more)"
                isFirst = false
            } else {
                header = "m=\(more)"
            }

            // APC: ESC _ G <header> ; <base64chunk> ESC \
            let sequence = "\u{1B}_G\(header);\(chunk)\u{1B}\\"
            output.append(contentsOf: sequence.utf8)
            offset = end
        }

        output.append(contentsOf: "\n".utf8)
        FileHandle.standardOutput.write(output)
    }

    // MARK: - iTerm2 inline image protocol

    // MARK: - Scaling

    private static func scaleImage(url: URL, scale: Double) throws -> Data {
        guard let source = NSImage(contentsOf: url),
              let cgImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw TerminalRenderError("Could not load image for scaling: \(url.path)")
        }
        let newWidth  = max(1, Int(Double(cgImage.width)  * scale))
        let newHeight = max(1, Int(Double(cgImage.height) * scale))

        guard let ctx = CGContext(
            data: nil,
            width: newWidth, height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: newWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw TerminalRenderError("Could not create CGContext for scaling")
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let scaled = ctx.makeImage() else {
            throw TerminalRenderError("Could not produce scaled image")
        }

        let rep = NSBitmapImageRep(cgImage: scaled)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            throw TerminalRenderError("Could not encode scaled image as PNG")
        }
        return png
    }

    /// Reference: https://iterm2.com/documentation-images.html
    private static func renderITerm2(data: Data, url: URL) {
        let base64 = data.base64EncodedString()
        let name = url.lastPathComponent.data(using: .utf8)!.base64EncodedString()
        let sequence = "\u{1B}]1337;File=name=\(name);size=\(data.count);inline=1;width=auto;height=auto;preserveAspectRatio=1:\(base64)\u{07}"
        FileHandle.standardOutput.write(Data((sequence + "\n").utf8))
    }
}

struct TerminalRenderError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
