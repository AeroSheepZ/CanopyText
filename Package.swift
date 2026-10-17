// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "CanopyText",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CanopyText", targets: ["CanopyText"])
    ],
    dependencies: [
        .package(url: "https://github.com/AeroSheepZ/CanopyDeck.git", exact: "0.11.1")
    ],
    targets: [
        .executableTarget(
            name: "CanopyText",
            dependencies: [
                .product(name: "CanopyToolWire", package: "CanopyDeck")
            ]
        )
    ]
)
