// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RefurbWatch",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(name: "RefurbWatch", targets: ["RefurbWatch"])
    ],
    targets: [
        .executableTarget(name: "RefurbWatch"),
        .testTarget(
            name: "RefurbWatchTests",
            dependencies: ["RefurbWatch"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
