---
name: arch-clean-architecture
description: Layered Clean Architecture for iOS — Domain (Entities, Use Cases, Repository protocols), Data (DTOs, repository impls), Presentation (any UI pattern, MVVM by default). Dependency rule outer→inner. Use for medium/large apps with non-trivial domain logic.
---

# Clean Architecture (Layered)

**Source references (study after reading this skill):**
- kudoleh/iOS-Clean-Architecture-MVVM — https://github.com/kudoleh/iOS-Clean-Architecture-MVVM
- nalexn/clean-architecture-swiftui — https://github.com/nalexn/clean-architecture-swiftui
- Alexey Naumov, *Clean Architecture for SwiftUI* — https://nalexn.github.io/clean-architecture-swiftui/
- Uncle Bob, *The Clean Architecture* — https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html

Code follows the kudoleh template's split:
- `Domain/Entities`, `Domain/UseCases`, `Domain/Interfaces/Repositories`
- `Data/Network`, `Data/Repositories`
- `Presentation/<Scene>/ViewModel`, `Presentation/<Scene>/View`
- `Application/DIContainer`, `Presentation/<Scene>/Flows/<Coordinator>`

## When to use

- Medium/large apps with non-trivial domain logic.
- SPM-modular setups (compose with `arch-modular-tma`).
- Regulated domains where business rules must be isolated from UI/persistence.

## Folder structure

Matches the worked example in `examples/clean-architecture/`:

```
Sources/
  App/
    UsersApp.swift
    DIContainer/AppDIContainer.swift
    DIContainer/UsersSceneDIContainer.swift
  Domain/
    User.swift                       ← Entity + UsersPage + errors
    UserRepository.swift             ← repository protocol (the inner boundary)
    UseCases/FetchUsersUseCase.swift
    UseCases/FetchUserUseCase.swift
    UseCases/UpdateUserUseCase.swift
  Data/
    LiveUserRepository.swift         ← DTOs + network impl behind the protocol
  Presentation/
    UsersScene/
      Flows/UsersFlowCoordinator.swift
      UserList/UserListViewModel.swift + UserListView.swift
      UserDetail/UserDetailViewModel.swift + UserDetailView.swift
Tests/
  FetchUsersUseCaseTests.swift       ← Domain logic, no simulator
  UserListViewModelTests.swift
  UserDetailViewModelTests.swift
  Support/FakeUserRepository.swift + Fixtures.swift
```

## Reference implementation

The full worked `UserList + UserDetail` feature lives in
**`examples/clean-architecture/`** — Domain entities + Use Cases, Data repository,
`@Observable` ViewModels, SwiftUI Views, the `UsersFlowCoordinator`, the
`AppDIContainer` / `UsersSceneDIContainer` composition root, and Domain + ViewModel
XCTest. Read it there rather than reproducing it here; key things to notice when you do:

- **Use Cases own business rules.** `DefaultFetchUsersUseCase` caps the page; `DefaultUpdateUserUseCase` validates the name before hitting the repository. ViewModels depend on Use Cases, never on the repository directly.
- **DTO ↔ Domain mapping sits at the Data boundary** (`LiveUserRepository`), never in Presentation.
- **The composition root is the only place that wires dependencies.** Modules never construct their own; `AppDIContainer` builds the repository, the per-scene container builds Use Cases and ViewModels.
- **Navigation state lives in the coordinator** (`UsersFlowCoordinator.path`); the ViewModel receives a `UserListActions` closure struct, not a navigation reference.

## Pros / cons

**Pros**
- Pure-Swift Domain → testable without simulator.
- Swappable infrastructure (network, persistence) behind protocols.
- Scales cleanly to multi-module codebases.
- Use Cases give business rules a single home.

**Cons**
- Many small types (DTOs ↔ Domain mappers, Use Case per op).
- Over-engineering risk for CRUD apps.
- "Where do VMs live" debate — answer: Presentation layer.

## Corner cases

- Use Case granularity: one per business operation. Even if a one-liner, future rules slot in.
- DTO mapping always at the Data boundary, never in Presentation.
- `Sendable` on Domain types is required for Swift 6 strict-concurrency.
- Composition root: do **not** let modules construct their own deps; the app composes everything in `AppDIContainer` + per-scene containers.
- Coordinator (Flow) lives in Presentation, owns navigation state; pass closures (Actions struct) into VMs.
- VMs depend on Use Cases, not repositories directly (commit to one direction).

## Anti-patterns

- `import UIKit`/`import SwiftUI` in Domain.
- Repository protocol in same module as its concrete implementation (breaks DI).
- Service locator / global `Container.shared`.
- VM importing `URLSession` directly.
- Use Case that's a thin pass-through with no place for rules to grow — fine if you commit, but document intent.

## Migration hand-off

- To TCA at Presentation: keep Domain/Data untouched; replace each VM with a Reducer using Use Cases as `@Dependency`.
- To Modular/TMA: each layer (`UserDomain`, `UserData`, `UserListFeature`, etc.) becomes its own module with an `Interface` target.
- Reverse direction (collapsing to MVVM-only): collapse Use Cases into the VM if rules are trivial; keep repository.
