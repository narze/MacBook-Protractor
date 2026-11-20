// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacBookProtractor",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacBookProtractor", targets: ["MacBookProtractor"]),
    ],
    targets: [
        .target(
            name: "LidAngleCore",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
        .executableTarget(
            name: "MacBookProtractor",
            dependencies: ["LidAngleCore"]
        ),
        .testTarget(
            name: "LidAngleCoreTests",
            dependencies: ["LidAngleCore"]
        ),
    ]
)
