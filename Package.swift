// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "JsonReader",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "JsonReader",
            dependencies: [],
            path: "."
        )
    ]
)