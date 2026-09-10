// swift-tools-version:5.9
import PackageDescription

// Builds the TCA feature code (Sources minus the app entry point) as an iOS
// library plus its test target. Verify on a Mac with:
//
//   xcodebuild test -scheme TCAExample -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
//
// `Sources/App` (the @main entry point) is excluded: it is the iOS app shell,
// not part of the architecture being demonstrated.
let package = Package(
    name: "TCAExample",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TCAExample", targets: ["TCAExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "TCAExample",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Sources",
            exclude: ["App"]
        ),
        .testTarget(
            name: "TCAExampleTests",
            dependencies: [
                "TCAExample",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Tests"
        )
    ]
)
