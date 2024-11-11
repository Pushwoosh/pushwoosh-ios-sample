// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "newdemo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "newdemo",
            targets: ["newdemo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Pushwoosh/Pushwoosh-XCFramework.git", from: "6.7.9"),
    ],
    targets: [
        .target(
            name: "newdemo",
            dependencies: [
                .product(name: "PushwooshFramework", package: "Pushwoosh-XCFramework")
            ],
            path: "Sources/newdemo"
        )
    ]
)
