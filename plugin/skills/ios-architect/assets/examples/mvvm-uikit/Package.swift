// swift-tools-version:5.9
import PackageDescription

// Builds the architectural code (Sources minus the app entry point) as an iOS
// library plus its test target. Verify on a Mac with:
//
//   xcodebuild build -scheme MVVMUIKitExample -destination 'generic/platform=iOS'
//   xcodebuild test  -scheme MVVMUIKitExample -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
//
// `Sources/App` (SceneDelegate / @main) is excluded: it is the iOS app shell,
// not part of the architecture being demonstrated, and an executable entry
// point cannot live in a unit-testable library target.
let package = Package(
    name: "MVVMUIKitExample",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MVVMUIKitExample", targets: ["MVVMUIKitExample"])
    ],
    targets: [
        .target(
            name: "MVVMUIKitExample",
            path: "Sources",
            exclude: ["App"]
        ),
        .testTarget(
            name: "MVVMUIKitExampleTests",
            dependencies: ["MVVMUIKitExample"],
            path: "Tests"
        )
    ]
)
