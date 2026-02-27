// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "tinyceo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TinyCEOCore", targets: ["TinyCEOCore"]),
        .executable(name: "tinyceo", targets: ["tinyceo"]),
        .executable(name: "tinyceo-app", targets: ["TinyCEOApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", exact: "6.2.3")
    ],
    targets: [
        .target(
            name: "TinyCEOCore",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .executableTarget(
            name: "tinyceo",
            dependencies: ["TinyCEOCore"]
        ),
        .executableTarget(
            name: "TinyCEOApp",
            dependencies: ["TinyCEOCore"],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "TinyCEOCoreTests",
            dependencies: [
                "TinyCEOCore",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
