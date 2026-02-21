// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "icon-generator",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SVGXML", targets: ["SVGXML"]),
        .library(name: "IconRendering", targets: ["IconRendering"]),
        .executable(name: "icon-generator", targets: ["icon-generator"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // SVGXML - XML/SVG infrastructure (no dependencies)
        .target(
            name: "SVGXML"
        ),

        // IconRendering - Core icon rendering (depends on SVGXML)
        .target(
            name: "IconRendering",
            dependencies: ["SVGXML"]
        ),

        // CLI executable (depends on IconRendering and ArgumentParser)
        .executableTarget(
            name: "icon-generator",
            dependencies: [
                "IconRendering",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),

        // Tests
        .testTarget(
            name: "SVGXMLTests",
            dependencies: ["SVGXML"]
        ),
        .testTarget(
            name: "IconRenderingTests",
            dependencies: ["IconRendering"]
        ),
        .testTarget(
            name: "icon-generatorTests",
            dependencies: ["icon-generator", "IconRendering"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
