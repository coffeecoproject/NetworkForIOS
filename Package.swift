// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NetworkForIOS",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "NetworkForIOS",
            targets: ["NetworkForIOS"]
        )
    ],
    targets: [
        .target(
            name: "NetworkForIOS"
        ),
        .testTarget(
            name: "NetworkForIOSTests",
            dependencies: ["NetworkForIOS"]
        )
    ]
)
