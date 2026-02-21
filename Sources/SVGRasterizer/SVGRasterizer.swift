import Foundation
import WebKit
import AppKit
import UniformTypeIdentifiers

/// Renders SVG content to PNG using WebKit
public final class SVGRasterizer: NSObject, @unchecked Sendable {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<CGImage, Error>?

    public override init() {
        super.init()
    }

    /// Render SVG string to CGImage
    @MainActor
    public func rasterize(svg: String, size: CGSize? = nil) async throws -> CGImage {
        // Parse SVG to get dimensions if not specified
        let (width, height) = size.map { (Int($0.width), Int($0.height)) } ?? parseSVGDimensions(svg)

        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: height), configuration: config)
        webView.navigationDelegate = self
        self.webView = webView

        // Create HTML with SVG embedded, with transparent background
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                * { margin: 0; padding: 0; }
                html, body { 
                    width: \(width)px; 
                    height: \(height)px; 
                    overflow: hidden;
                    background: transparent;
                }
                svg { 
                    width: \(width)px; 
                    height: \(height)px;
                    display: block;
                }
            </style>
        </head>
        <body>
        \(svg)
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    /// Render SVG file to CGImage
    @MainActor
    public func rasterize(svgURL: URL, size: CGSize? = nil) async throws -> CGImage {
        let svg = try String(contentsOf: svgURL, encoding: .utf8)
        return try await rasterize(svg: svg, size: size)
    }

    /// Render SVG string to PNG data
    @MainActor
    public func rasterizeToPNG(svg: String, size: CGSize? = nil) async throws -> Data {
        let image = try await rasterize(svg: svg, size: size)
        return try pngData(from: image)
    }

    /// Render SVG and save to PNG file
    @MainActor
    public func rasterizeToFile(svg: String, outputURL: URL, size: CGSize? = nil) async throws {
        let data = try await rasterizeToPNG(svg: svg, size: size)
        try data.write(to: outputURL)
    }

    // MARK: - Private Helpers

    private func parseSVGDimensions(_ svg: String) -> (Int, Int) {
        // Try to parse width/height from SVG tag
        let widthPattern = #"width="(\d+)"#
        let heightPattern = #"height="(\d+)"#

        var width = 256
        var height = 256

        if let match = svg.range(of: widthPattern, options: .regularExpression),
           let value = Int(svg[match].replacingOccurrences(of: "width=\"", with: "")) {
            width = value
        }

        if let match = svg.range(of: heightPattern, options: .regularExpression),
           let value = Int(svg[match].replacingOccurrences(of: "height=\"", with: "")) {
            height = value
        }

        return (width, height)
    }

    private func pngData(from image: CGImage) throws -> Data {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw SVGRasterizerError.pngConversionFailed
        }
        return data
    }

    @MainActor
    private func captureImage() async throws -> CGImage {
        guard let webView = webView else {
            throw SVGRasterizerError.webViewNotInitialized
        }

        let config = WKSnapshotConfiguration()
        config.snapshotWidth = NSNumber(value: Int(webView.bounds.width))

        let image = try await webView.takeSnapshot(configuration: config)

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw SVGRasterizerError.snapshotFailed
        }

        return cgImage
    }
}

// MARK: - WKNavigationDelegate

extension SVGRasterizer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            do {
                // Small delay to ensure rendering is complete
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms

                let image = try await captureImage()
                continuation?.resume(returning: image)
                continuation = nil
            } catch {
                continuation?.resume(throwing: error)
                continuation = nil
            }
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - Errors

public enum SVGRasterizerError: Error, LocalizedError {
    case webViewNotInitialized
    case snapshotFailed
    case pngConversionFailed

    public var errorDescription: String? {
        switch self {
        case .webViewNotInitialized:
            return "WebView not initialized"
        case .snapshotFailed:
            return "Failed to capture snapshot from WebView"
        case .pngConversionFailed:
            return "Failed to convert image to PNG"
        }
    }
}
