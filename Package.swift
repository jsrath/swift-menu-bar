// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftMenuBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SwiftMenuBar", targets: ["SwiftMenuBar"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftMenuBar",
            path: "Sources/SwiftMenuBar"
        )
    ]
)
