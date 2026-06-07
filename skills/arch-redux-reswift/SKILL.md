---
name: arch-redux-reswift
description: Redux / ReSwift for iOS. Single global store, pure reducers, actions, middleware for side effects. Use when sharing business logic across platforms or when a team has Redux background. Consider TCA first for greenfield SwiftUI.
---

# Redux / ReSwift

**Source references:**
- ReSwift/ReSwift — https://github.com/ReSwift/ReSwift
- ReSwift CounterExample — https://github.com/ReSwift/CounterExample-Navigation-TimeTravel
- Dan Abramov, *Three Principles* — https://redux.js.org/understanding/thinking-in-redux/three-principles

## When to use

- Cross-platform business logic (portable Swift, or shared semantics with Android Redux/Kotlin Multiplatform).
- Teams with prior Redux experience.
- Consider TCA first on greenfield SwiftUI.

## Folder structure

```
App/
  UsersApp.swift
  Store/
    AppState.swift
    AppAction.swift
    AppReducer.swift
    AppStore.swift
Middleware/
  AsyncMiddleware.swift
Features/
  UserList/
    UserListState.swift
    UserListAction.swift
    UserListReducer.swift
    UserListView.swift
  UserDetail/
    UserDetailState.swift
    UserDetailAction.swift
    UserDetailReducer.swift
    UserDetailView.swift
Domain/
  User.swift
  UserRepository.swift
```

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/redux-reswift/`** —
a single `AppStore`, per-feature `State`/`Action`/`Reducer` triples, an async
middleware bridging the repository to dispatched actions, and SwiftUI views
subscribed to the store. `Domain` + `Data` follow `skills/REFERENCE_FEATURE.md` (vendored per example).

> **Requires the `ReSwift` package**, wired in `examples/redux-reswift/Package.swift`.
> It builds and tests as a standalone SPM package.

Key things to notice:

- **One global `AppState`**, composed from feature sub-states; the store is the single source of truth and views read slices of it.
- **Reducers are pure `(State, Action) -> State`** — no async, no side effects; this is why they are the easiest tests in the whole bundle.
- **Side effects live in middleware** — `AsyncMiddleware` calls the repository and dispatches success/failure actions back into the store.
- **Views dispatch actions, never mutate state directly**; navigation is itself modeled as state in the store.

## Pros / cons

**Pros**: Predictable single store; replayable; reducers are pure functions; portable across platforms.
**Cons**: Async/middleware story weaker than TCA's `Effect`; ecosystem stagnant on iOS; boilerplate per feature.

## Corner cases

- `@MainActor` on store dispatches when updating UI; `MainActor.run { ... }` from middleware Task.
- Do not encode navigation in `AppState`; let Coordinator/Router observe and react.
- All state types must be `Equatable` for change detection.
- Pair `subscribe`/`unsubscribe` on view appear/disappear; missing unsubscribe leaks observers.
- Middleware order matters; logging middleware sits in front of async.

## Anti-patterns

- Side effects inside reducers.
- Reference types in state.
- Multiple stores for "performance" (use selectors + `Equatable` projections).
- Subscribing per cell.

## Migration hand-off

- To TCA: largely mechanical — wrap actions in `@Reducer`, replace middleware with `Effect.run`, get `TestStore` + macros.
- To MVVM: split store into per-feature `@Observable` models; lose replay/time-travel.
- To Clean Architecture at Presentation: keep store; pull non-trivial business rules into Use Cases called from middleware.
