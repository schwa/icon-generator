// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "icon-generator",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "icon-generator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "icon-generatorTests",
            dependencies: ["icon-generator"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
