// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iPowerMenu",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "iPowerMenu",
            targets: ["HomeAssistantMenuBar"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "HomeAssistantMenuBar",
            dependencies: []
        )
    ]
)