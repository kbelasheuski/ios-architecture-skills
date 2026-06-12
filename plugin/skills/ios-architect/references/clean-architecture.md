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
- SPM-modular setups (compose with `modular-tma`).
- Regulated domains where business rules must be isolated from UI/persistence.

## Decision examples

- Use this when domain rules must survive UI and data-source changes.
- Reject it for small UI-only features where layers would hide simple behavior.
- First safe slice: extract a Use Case and Repository protocol around one network-backed screen.

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

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html | Dependency rule and use-case isolation are the claims proven by the Domain/Data/Presentation example. | `examples/clean-architecture/` |

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


## Testing strategy

- Unit test Use Cases and Domain policies without UIKit, SwiftUI, or network.
- Test repository implementations at the Data boundary, including DTO mapping and error translation.
- Presentation tests should use fake use cases and assert only UI-facing state.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert use case fetches users through the repository protocol and presenter state updates. | Use-case test plus repository fake |
| Repository failure | Assert domain/data failure is mapped at the presentation boundary. | Repository fake error branch |
| Pagination | Assert loading next page calls the use case with the next page only once. | Repository fake fetchPageCalls |
| Detail save | Assert update use case changes the presentation state without importing infrastructure. | Repository fake updateCalls |

## Concurrency and cancellation

- Use Cases should be async and cancellation-aware; they should not swallow `CancellationError` as a domain failure.
- Presentation models own UI task lifetime and publish on the main actor.
- Data adapters translate transport errors at the boundary and leave domain models transport-free.

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

## Failure modes

- Domain imports UI or infrastructure.
- Use Cases are skipped and ViewModels call repositories directly.
- Repository protocols live beside concrete implementations.
- Composition root is replaced with a global container.

## Review checklist

- Does every dependency point inward toward Domain?
- Are business rules in Use Cases, not ViewModels or repositories?
- Are DTO/domain mappings at the Data boundary?
- Can Domain tests run without simulator or network?
- Is dependency construction limited to the composition root?
