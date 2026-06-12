// swift-tools-version:5.9
import PackageDescription

// Builds the architectural code (Sources minus the app entry point) as an iOS
// library plus its test target. Verify on a Mac with:
//
//   xcodebuild build -scheme MVPExample -destination 'generic/platform=iOS'
//   xcodebuild test  -scheme MVPExample -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
//
// `Sources/App` (SceneDelegate / @main) is excluded: it is the iOS app shell,
// not part of the architecture being demonstrated, and an executable entry
// point cannot live in a unit-testable library target.
let package = Package(
    name: "MVPExample",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MVPExample", targets: ["MVPExample"])
    ],
    targets: [
        .target(
            name: "MVPExample",
            path: "Sources",
            exclude: ["App"]
        ),
        .testTarget(
            name: "MVPExampleTests",
            dependencies: ["MVPExample"],
            path: "Tests"
        )
    ]
)
