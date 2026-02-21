import Testing
import Foundation
@testable import IconComposerFormat

@Suite("IconColor Tests")
struct IconColorTests {
    @Test("Parse extended-srgb color")
    func parseExtendedSRGB() throws {
        let color = try IconColor(parsing: "extended-srgb:0.00000,0.53333,1.00000,1.00000")
        #expect(color.colorSpace == .extendedSRGB)
        #expect(color.components.count == 4)
        #expect(color.red == 0.0)
        #expect(color.green! ~= 0.53333)
        #expect(color.blue == 1.0)
        #expect(color.alpha == 1.0)
    }

    @Test("Parse display-p3 color")
    func parseDisplayP3() throws {
        let color = try IconColor(parsing: "display-p3:0.90196,0.41176,0.40392,1.00000")
        #expect(color.colorSpace == .displayP3)
        #expect(color.components.count == 4)
    }

    @Test("Parse extended-gray color")
    func parseExtendedGray() throws {
        let color = try IconColor(parsing: "extended-gray:0.86665,1.00000")
        #expect(color.colorSpace == .extendedGray)
        #expect(color.components.count == 2)
        #expect(color.luminance! ~= 0.86665)
        #expect(color.alpha == 1.0)
        #expect(color.red == nil)
    }

    @Test("Round-trip encoding")
    func roundTrip() throws {
        let original = try IconColor(parsing: "extended-srgb:0.50000,0.25000,0.75000,1.00000")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IconColor.self, from: encoded)
        #expect(decoded.colorSpace == original.colorSpace)
        #expect(decoded.components == original.components)
    }

    @Test("Invalid format throws")
    func invalidFormat() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "invalid")
        }
    }

    @Test("Unknown color space throws")
    func unknownColorSpace() {
        #expect(throws: IconColorError.self) {
            try IconColor(parsing: "unknown:0.5,0.5,0.5,1.0")
        }
    }
}

@Suite("IconFill Tests")
struct IconFillTests {
    @Test("Decode automatic")
    func decodeAutomatic() throws {
        let json = #""automatic""#
        let fill = try JSONDecoder().decode(IconFill.self, from: json.data(using: .utf8)!)
        #expect(fill == .automatic)
    }

    @Test("Decode system-light")
    func decodeSystemLight() throws {
        let json = #""system-light""#
        let fill = try JSONDecoder().decode(IconFill.self, from: json.data(using: .utf8)!)
        #expect(fill == .systemLight)
    }

    @Test("Decode automatic-gradient")
    func decodeAutomaticGradient() throws {
        let json = #"{"automatic-gradient": "extended-srgb:0.00000,0.53333,1.00000,1.00000"}"#
        let fill = try JSONDecoder().decode(IconFill.self, from: json.data(using: .utf8)!)
        if case .automaticGradient(let color) = fill {
            #expect(color.colorSpace == .extendedSRGB)
        } else {
            Issue.record("Expected automatic-gradient fill")
        }
    }

    @Test("Decode solid")
    func decodeSolid() throws {
        let json = #"{"solid": "gray:0.94154,1.00000"}"#
        let fill = try JSONDecoder().decode(IconFill.self, from: json.data(using: .utf8)!)
        if case .solid(let color) = fill {
            #expect(color.colorSpace == .gray)
        } else {
            Issue.record("Expected solid fill")
        }
    }

    @Test("Round-trip encoding")
    func roundTrip() throws {
        let fills: [IconFill] = [
            .automatic,
            .systemLight,
            .systemDark,
            .solid(try IconColor(parsing: "srgb:1.0,0.0,0.0,1.0")),
            .automaticGradient(try IconColor(parsing: "display-p3:0.5,0.5,1.0,1.0"))
        ]

        for original in fills {
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(IconFill.self, from: encoded)
            #expect(decoded == original)
        }
    }
}

@Suite("IconBundle Tests")
struct IconBundleTests {
    @Test("Write bundle and verify structure")
    func writeBundle() throws {
        // Create a document
        var document = IconDocument()
        document.fill = .automaticGradient(try IconColor(parsing: "srgb:0.0,0.5,1.0,1.0"))
        document.groups = [
            IconGroup(layers: [
                IconLayer(name: "test", imageName: "test.svg", glass: true)
            ], shadow: .neutral, translucency: .default)
        ]
        document.supportedPlatforms = .allPlatforms

        var bundle = IconBundle(document: document)
        bundle.setAsset(name: "test.svg", data: "<svg></svg>".data(using: .utf8)!)

        // Write to temp directory
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("icon")

        try bundle.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Verify structure exists
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: tempURL.appendingPathComponent("icon.json").path))
        #expect(fileManager.fileExists(atPath: tempURL.appendingPathComponent("Assets/test.svg").path))

        // Verify icon.json is valid JSON
        let jsonData = try Data(contentsOf: tempURL.appendingPathComponent("icon.json"))
        let decoded = try JSONDecoder().decode(IconDocument.self, from: jsonData)
        #expect(decoded.groups.count == 1)
        #expect(decoded.groups[0].layers[0].name == "test")
        #expect(decoded.groups[0].layers[0].glass == true)

        // Verify asset content
        let assetData = try Data(contentsOf: tempURL.appendingPathComponent("Assets/test.svg"))
        #expect(String(data: assetData, encoding: .utf8) == "<svg></svg>")
    }

    @Test("Write bundle with multiple assets")
    func writeMultipleAssets() throws {
        var document = IconDocument()
        document.groups = [
            IconGroup(layers: [
                IconLayer(name: "fg", imageName: "foreground.svg"),
                IconLayer(name: "bg", imageName: "background.png")
            ])
        ]

        var bundle = IconBundle(document: document)
        bundle.setAsset(name: "foreground.svg", data: Data(repeating: 1, count: 100))
        bundle.setAsset(name: "background.png", data: Data(repeating: 2, count: 200))

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("icon")

        try bundle.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Verify both assets written
        let fgData = try Data(contentsOf: tempURL.appendingPathComponent("Assets/foreground.svg"))
        let bgData = try Data(contentsOf: tempURL.appendingPathComponent("Assets/background.png"))
        #expect(fgData.count == 100)
        #expect(bgData.count == 200)
    }
}

@Suite("Specialization Tests")
struct SpecializationTests {
    @Test("Decode fill specializations")
    func decodeFillSpecializations() throws {
        let json = """
        [
            {"value": "automatic"},
            {"appearance": "dark", "value": {"automatic-gradient": "srgb:0.5,0.5,0.5,1.0"}}
        ]
        """
        let specs = try JSONDecoder().decode([Specialization<IconFill>].self, from: json.data(using: .utf8)!)

        #expect(specs.count == 2)
        #expect(specs[0].isDefault == true)
        #expect(specs[0].value == .automatic)
        #expect(specs[1].appearance == .dark)
    }

    @Test("Decode opacity specializations")
    func decodeOpacitySpecializations() throws {
        let json = """
        [
            {"value": 1.0},
            {"appearance": "dark", "value": 0.5},
            {"appearance": "tinted", "value": 0.15}
        ]
        """
        let specs = try JSONDecoder().decode([Specialization<Double>].self, from: json.data(using: .utf8)!)

        #expect(specs.count == 3)
        #expect(specs[0].value == 1.0)
        #expect(specs[1].value == 0.5)
        #expect(specs[2].appearance == .tinted)
    }
}

@Suite("IconDocument Tests")
struct IconDocumentTests {
    @Test("Encode document with all features")
    func encodeFullDocument() throws {
        var document = IconDocument()
        document.colorSpaceForUntaggedSVGColors = "display-p3"
        document.fill = .automaticGradient(try IconColor(parsing: "display-p3:0.0,0.5,1.0,1.0"))
        document.groups = [
            IconGroup(
                name: "Main",
                layers: [
                    IconLayer(
                        name: "icon",
                        imageName: "icon.svg",
                        fill: .automatic,
                        blendMode: .normal,
                        opacity: 0.9,
                        glass: true,
                        position: IconPosition(scale: 1.2, translationX: 0, translationY: 10)
                    )
                ],
                shadow: IconShadow(kind: .layerColor, opacity: 0.6),
                translucency: IconTranslucency(enabled: true, value: 0.4),
                lighting: .combined,
                specular: true
            )
        ]
        document.supportedPlatforms = SupportedPlatforms(
            circles: ["watchOS"],
            squares: .shared
        )

        // Encode and decode to verify round-trip
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)

        let decoded = try JSONDecoder().decode(IconDocument.self, from: data)

        #expect(decoded.colorSpaceForUntaggedSVGColors == "display-p3")
        #expect(decoded.groups.count == 1)
        #expect(decoded.groups[0].name == "Main")
        #expect(decoded.groups[0].layers[0].glass == true)
        #expect(decoded.groups[0].layers[0].position?.scale == 1.2)
        #expect(decoded.groups[0].specular == true)
        #expect(decoded.supportedPlatforms?.circles == ["watchOS"])
        #expect(decoded.supportedPlatforms?.squares == .shared)
    }
}

// Helper for floating point comparison
private func ~= (lhs: Double, rhs: Double) -> Bool {
    abs(lhs - rhs) < 0.00001
}
