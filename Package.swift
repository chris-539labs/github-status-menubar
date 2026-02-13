// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GitHubStatus",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "GitHubStatus",
            path: "GitHubStatus",
            exclude: ["App/Info.plist"]
        )
    ]
)
