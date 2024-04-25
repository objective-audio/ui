// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ui",
    platforms: [.macOS(.v10_15), .iOS(.v13), .macCatalyst(.v13)],
    products: [
        .library(
            name: "ui",
            targets: ["ui"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/objective-audio/observing.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ui-swift-bundle",
            resources: [.process("Resources")]
        ),
        .target(
            name: "ui-bundle",
            dependencies: ["ui-swift-bundle"]
        ),
        .target(
            name: "ui-objc"
        ),
        .target(
            name: "ui-view-objc",
            dependencies: [
                "ui-objc"
            ]
        ),
        .target(
            name: "ui",
            dependencies: [
                .product(name: "observing", package: "observing"),
                "ui-bundle",
                "ui-view-objc"
            ],
            cSettings: [
                .unsafeFlags(["-fmodules"]),
            ],
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("MetalPerformanceShaders"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreText"),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "ui-tests",
            dependencies: [
                "ui"
            ],
            cxxSettings: [
                .unsafeFlags(["-fcxx-modules"]),
            ]),
        .testTarget(
            name: "ui-bundle-tests",
            dependencies: [
                "ui-swift-bundle"
            ]
        )
    ],
    cLanguageStandard: .gnu18,
    cxxLanguageStandard: .gnucxx2b
)
