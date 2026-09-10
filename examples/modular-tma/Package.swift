// swift-tools-version:5.9
import PackageDescription

// Real multi-target SwiftPM graph — the Interface/Sources boundary is enforced by the
// compiler, not just folders. Each feature's implementation (Model/View) is internal to
// its `<Feature>` target; siblings and the app may depend only on `<Feature>Interface`.
// Verify on a Mac with:
//
//   xcodebuild test -scheme ModularTMAExample-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
//
// Apps/ModularApps.xcodeproj builds the main app and standalone feature demo.
// Their entrypoints stay outside the seven production library targets.
let package = Package(
    name: "ModularTMAExample",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ModularTMAExample", targets: ["UserListFeature", "UserDetailFeature", "UserData"]),
        .library(name: "UserListFeature", targets: ["UserListFeature"])
    ],
    targets: [
        .target(name: "Domain", path: "Sources/Domain"),
        .target(name: "UserDomain", dependencies: ["Domain"], path: "Sources/Modules/UserDomain"),
        .target(name: "UserData", dependencies: ["Domain"], path: "Sources/Data"),
        .target(name: "UserListFeatureInterface", dependencies: ["Domain"],
                path: "Sources/Modules/UserListFeature/Interface"),
        .target(name: "UserListFeature", dependencies: ["UserListFeatureInterface", "UserDomain"],
                path: "Sources/Modules/UserListFeature/Sources"),
        .target(name: "UserDetailFeatureInterface", dependencies: ["Domain"],
                path: "Sources/Modules/UserDetailFeature/Interface"),
        .target(name: "UserDetailFeature", dependencies: ["UserDetailFeatureInterface", "UserDomain"],
                path: "Sources/Modules/UserDetailFeature/Sources"),
        .testTarget(
            name: "ModularTMAExampleTests",
            dependencies: ["Domain", "UserDomain", "UserListFeature"],
            path: "Tests"
        )
    ]
)
