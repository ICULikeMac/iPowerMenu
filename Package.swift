// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HomeAssistantMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "HomeAssistantMenuBar",
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