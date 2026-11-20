// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LidAngle",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LidAngleApp", targets: ["LidAngleApp"]),
    ],
    targets: [
        .target(
            name: "LidAngleCore",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
        .executableTarget(
            name: "LidAngleApp",
            dependencies: ["LidAngleCore"]
        ),
        .testTarget(
            name: "LidAngleCoreTests",
            dependencies: ["LidAngleCore"]
        ),
    ]
)
