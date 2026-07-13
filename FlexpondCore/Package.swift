// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FlexpondCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "FlexpondCore", targets: ["FlexpondCore"])
    ],
    targets: [
        .target(name: "FlexpondCore"),
        .testTarget(name: "FlexpondCoreTests", dependencies: ["FlexpondCore"]),
        .executableTarget(name: "Smoke", dependencies: ["FlexpondCore"])
    ]
)
