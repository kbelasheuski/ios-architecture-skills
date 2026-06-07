// Tuist template for a feature module: Interface + Sources + Tests + Example.
// Run `tuist generate` to materialise the Xcode workspace from these descriptors.

import ProjectDescription

public extension Project {
    static func featureModule(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Project {
        Project(
            name: name,
            targets: [
                .target(
                    name: "\(name)Interface",
                    destinations: .iOS,
                    product: .framework,
                    bundleId: "com.example.\(name).interface",
                    deploymentTargets: .iOS("17.0"),
                    sources: ["Interface/**"]
                ),
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .framework,
                    bundleId: "com.example.\(name)",
                    deploymentTargets: .iOS("17.0"),
                    sources: ["Sources/**"],
                    dependencies: [.target(name: "\(name)Interface")] + dependencies
                ),
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "com.example.\(name).tests",
                    deploymentTargets: .iOS("17.0"),
                    sources: ["Tests/**"],
                    dependencies: [.target(name: name)]
                ),
                .target(
                    name: "\(name)Example",
                    destinations: .iOS,
                    product: .app,
                    bundleId: "com.example.\(name).example",
                    deploymentTargets: .iOS("17.0"),
                    infoPlist: .default,
                    sources: ["Example/**"],
                    dependencies: [.target(name: name)]
                )
            ]
        )
    }
}
