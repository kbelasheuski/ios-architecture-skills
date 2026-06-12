# MVVM-C (MVVM + Coordinator)

**Source references:**
- Soroush Khanlou, *Coordinators Redux* — https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps
- raywenderlich/advanced-ios-app-arch-materials — https://github.com/raywenderlich/advanced-ios-app-arch-materials
- kudoleh/iOS-Clean-Architecture-MVVM (FlowCoordinator pattern) — https://github.com/kudoleh/iOS-Clean-Architecture-MVVM/blob/master/ExampleMVVM/Presentation/MoviesScene/Flows/MoviesSearchFlowCoordinator.swift

Two variants below — pick the one matching your UI framework.

## When to use

- UIKit medium/large apps with deep-linking, A/B routed flows, reusable flows.
- SwiftUI apps where `NavigationStack` alone is too anaemic (programmatic routing, deep-linking).

## Decision examples

- Use this when MVVM screens already work but navigation is duplicated or hard to test.
- Reject it when navigation is simple and local; plain MVVM is cheaper.
- First safe slice: introduce one Coordinator around the current screen and move only push/present decisions first.

## Folder structure

UIKit variant (Coordinator object owns a `UINavigationController`):

```
App/SceneDelegate.swift
Coordinators/
  Coordinator.swift            ← base protocol
  AppCoordinator.swift
  UserFlowCoordinator.swift
Features/
  UserList/UserListViewController.swift + UserListViewModel.swift
  UserDetail/UserDetailViewController.swift + UserDetailViewModel.swift
Domain/  Data/
```

SwiftUI Router variant (what the example ships):

```
Sources/
  App/UsersApp.swift
  Router/Route.swift + AppRouter.swift   ← @Observable path-based router
  Features/
    UserList/UserListModel.swift + UserListView.swift
    UserDetail/UserDetailModel.swift + UserDetailView.swift
  Domain/  Data/
```

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps | Coordinator-owned navigation is the boundary that keeps screen models free of push/present calls. | `examples/mvvm-c/` |

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/mvvm-c/`**,
implemented as the **SwiftUI Router variant** — an `@Observable @MainActor AppRouter`
holding a `[Route]` path, MVVM models per feature, and `Domain` + `Data` that follow
`skills/ios-architect/references/reference-feature.md` (vendored per example). Key things to notice:

- **The router is the coordinator** — `AppRouter.path` drives a `NavigationStack(path:)`; models trigger navigation through an injected closure, not by holding the router type.
- **`Route` is a `Hashable` enum** — deep-linking and programmatic navigation reduce to appending routes.
- **Models stay UIKit/SwiftUI-free** and depend only on `UserRepository`; the View owns the model via `@State`.
- For the **UIKit variant**, the same separation holds with a `Coordinator` object owning a `UINavigationController` instead of a `NavigationStack`.


## Testing strategy

- Test ViewModels without navigation; assert route events or callbacks separately.
- Cover repository failure and route rejection paths without pushing UIKit controllers.
- Test coordinators/routers with typed route inputs and fake factories, including deep links and back-stack behavior.
- Keep integration coverage around the composition root so feature factories remain wired correctly.
- Keep route and dependency tests deterministic with controlled coordinator outputs.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert the ViewModel loads users without knowing about navigation controllers. | FakeUserRepository plus coordinator spy |
| Repository failure | Assert failure state is emitted without starting a route. | Coordinator spy no-call assertion |
| User tap | Assert selecting a row asks the coordinator to open the detail route. | Coordinator spy route assertion |
| Detail save | Assert save updates the repository and lets coordinator-owned navigation remain separate. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- ViewModels own feature async work; coordinators own navigation lifetime, not network tasks.
- Route mutations should happen on the main actor for UIKit and SwiftUI navigation APIs.
- Cancel feature work when the coordinator ends the flow, or pass cancellation through the feature's lifecycle event.

## Pros / cons

**Pros**
- Decouples navigation; deep-linking is straightforward.
- Coordinators reusable across flows.
- Clear navigation ownership.

**Cons**
- Coordinator retain-cycle traps (forget `weak self` in closures).
- SwiftUI `NavigationStack` only pops from the tail — middle removal needs full path reset.
- Extra layer to reason about.

## Corner cases

- Use `weak self` in every closure captured by Coordinator.
- Coordinator children are owned by their parent; the parent calls `finish()` to detach.
- Pass `onSelect`/`onSaved` closures into VMs instead of injecting the Coordinator (Coordinator stays at one layer above VMs).
- SwiftUI Router: store the path in `@Observable` so the view sees granular invalidation.
- Universal links: parse `URL` → `[Route]` outside the Router, then assign to `router.path`.
- Avoid global Router singleton — inject via `.environment(router)` (it's fine for AppRouter, but **never** for repositories).

## Anti-patterns

- VM calls `navigationController.pushViewController` directly.
- Coordinator holds `[UIViewController]` references.
- Router as global `Router.shared` (breaks DI and previews).
- Mixing imperative `present(_:animated:)` from VCs with Coordinator-driven flow.

## Migration hand-off

- To VIPER: extract Interactor (rules) + Presenter (formatting) out of VM; Coordinator becomes Router.
- To TCA: replace AppRouter with TCA `StackState`/`StackActionOf`; merge VM into Reducer.
- To Clean Architecture: pull repository contracts into a Domain module; introduce Use Cases.

## Failure modes

- Coordinator becomes a service locator.
- ViewModel holds the concrete coordinator instead of emitting navigation events.
- SwiftUI route path has several owners.
- UIKit child coordinators are retained forever.

## Review checklist

- Is navigation owned by one coordinator/router per flow?
- Are routes typed values or explicit coordinator methods?
- Do models expose callbacks or route intents, not concrete navigation objects?
- Are deep links parsed and tested outside views?
- Are child coordinators released when flows finish?
