# Modular / TMA — Example (Tuist + SPM)

Each feature is its own module with `Interface` (public API) + `Sources` (impl) + `Tests` + `Example` (mini-app per feature for fast iteration).

> **Requires:** Tuist (or hand-rolled SPM workspace). Layout shown is canonical TMA. Templates in `Tuist/ProjectDescriptionHelpers/`.

## Layout

```
Sources/
  App/UsersApp.swift                    // composition root, depends on *Interface only
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

Module dependency rule: **App depends only on `*Interface` targets**. `Sources` is opaque to siblings. Features depend on `UserDomain` + `Core/*`. `UserData` depends on `UserDomain`.

## Real-world refs

- Tuist, *The Modular Architecture* — https://docs.tuist.dev/en/guides/develop/projects/tma-architecture
- Apple, *Bundling Resources with SPM* — https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package

## How testing works

Each module has its own `Tests/` target. Domain layer is pure Swift → fastest to test. Feature modules tested by injecting Use Case protocols + `FakeUserRepository`. Per-feature `Example` apps allow running the feature in isolation without launching the full app (also useful for snapshot tests).
