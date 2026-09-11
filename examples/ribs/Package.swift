// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RIBsExample",
    platforms: [.iOS(.v17)],
    products: [.library(name: "RIBsExample", targets: ["RIBsExample"])],
    dependencies: [
        .package(url: "https://github.com/uber/RIBs-iOS.git", exact: "1.1.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift", exact: "6.9.0")
    ],
    targets: [
        .target(name: "RIBsExample", dependencies: [
            .product(name: "RIBs", package: "RIBs-iOS"),
            .product(name: "RxSwift", package: "RxSwift")
        ], path: "Sources", exclude: ["App"]),
        .testTarget(name: "RIBsExampleTests", dependencies: [
            "RIBsExample",
            .product(name: "RIBs", package: "RIBs-iOS"),
            .product(name: "RxSwift", package: "RxSwift")
        ], path: "Tests")
    ]
)
