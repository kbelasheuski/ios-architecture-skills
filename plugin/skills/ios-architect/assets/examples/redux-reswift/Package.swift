// swift-tools-version:5.9
import PackageDescription

// Builds the Redux/ReSwift code (Sources minus the @main entry point) as an iOS
// library plus its test target. Verify on a Mac with:
//
//   xcodebuild test -scheme ReduxReSwiftExample -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
//
// Only `Sources/App/UsersApp.swift` (the @main shell) is excluded; the global
// store, reducers, and actions under `Sources/App/Store` are part of the
// architecture and stay in the library target.
let package = Package(
    name: "ReduxReSwiftExample",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ReduxReSwiftExample", targets: ["ReduxReSwiftExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReSwift/ReSwift", from: "6.1.1")
    ],
    targets: [
        .target(
            name: "ReduxReSwiftExample",
            dependencies: [
                .product(name: "ReSwift", package: "ReSwift")
            ],
            path: "Sources",
            exclude: ["App/UsersApp.swift"]
        ),
        .testTarget(
            name: "ReduxReSwiftExampleTests",
            dependencies: ["ReduxReSwiftExample"],
            path: "Tests"
        )
    ]
)
