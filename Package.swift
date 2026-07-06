// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DepthExporter",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "depth-exporter",
            targets: ["DepthExporterCLI"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DepthExporterCLI"
        )
    ]
)
