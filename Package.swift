// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TodoWidget",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "TodoWidget",
            targets: ["TodoWidget"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "TodoWidget"
        ),
    ]
)
