# Modular / TMA — Example (Tuist + SPM)

Each feature is its own module with `Interface` (public API) + `Sources` (impl) + `Tests` + `Example` (mini-app per feature for fast iteration).

> **Requires:** Xcode with an iOS 17+ SDK. Open `Apps/ModularApps.xcodeproj`; `UsersApp` builds the composition root and `UserListDemo` runs the feature with local data. The main app requires a configured API endpoint. Tuist templates remain optional.

## Layout

```
Sources/
  App/UsersApp.swift                    // composition root, constructs implementation factories
  Modules/
    Core/                                // shared kernel
      (DesignSystem, Networking, etc.)
    UserDomain/                          // pure Swift, no UI imports
      User.swift                         (shared)
      UserRepository.swift               (shared)
      FetchUsersUseCase.swift
      FetchUserUseCase.swift
      UpdateUserUseCase.swift
    UserData/                            // concrete repo, hidden behind UserDomain protocol
      LiveUserRepository.swift           (shared)
    UserListFeature/
      Interface/UserListFeatureInterface.swift   // public Factory protocol
      Sources/UserListFeatureFactoryLive.swift   // hidden impl
      Sources/UserListModel.swift
      Sources/UserListView.swift
      Example/UserListExampleApp.swift           // mini-app
    UserDetailFeature/
      Interface/...
      Sources/...
      Example/...
Tuist/
  ProjectDescriptionHelpers/Project+Templates.swift
Tests/
  UserListModelTests.swift
  UserDomainTests.swift
  Support/
```

Module dependency rule: **Sibling features depend only on `*Interface` targets**. The app composition root may construct implementation factories; `Sources` stays opaque to siblings. Features depend on `UserDomain` + `Core/*`. `UserData` depends on `UserDomain`.

## Real-world refs

- Tuist, *The Modular Architecture* — https://docs.tuist.dev/en/guides/develop/projects/tma-architecture
- Apple, *Bundling Resources with SPM* — https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package

## How testing works

Run `xcodebuild test -scheme ModularTMAExample-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` for the package test target. Domain layer is pure Swift → fastest to test. Feature modules tested by injecting Use Case protocols + `FakeUserRepository`. Per-feature `Example` apps allow running the feature in isolation without launching the full app (also useful for snapshot tests).
