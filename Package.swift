// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-cli-core",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CLICore", targets: ["CLICore"])
    ],
    targets: [
        .target(name: "CLICore"),
        .testTarget(name: "CLICoreTests", dependencies: ["CLICore"])
    ]
)
