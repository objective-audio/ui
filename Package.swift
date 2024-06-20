// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ui",
    platforms: [.macOS(.v14), .iOS(.v17), .macCatalyst(.v17)],
    products: [
        .library(
            name: "ui",
            targets: ["ui"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/objective-audio/cpp_utils.git", branch: "master"),
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
                .product(name: "cpp-utils", package: "cpp_utils"),
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
