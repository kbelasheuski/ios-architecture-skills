# Redux / ReSwift

**Source references:**
- ReSwift/ReSwift — https://github.com/ReSwift/ReSwift
- ReSwift CounterExample — https://github.com/ReSwift/CounterExample-Navigation-TimeTravel
- Dan Abramov, *Three Principles* — https://redux.js.org/understanding/thinking-in-redux/three-principles

## When to use

- Cross-platform business logic (portable Swift, or shared semantics with Android Redux/Kotlin Multiplatform).
- Teams with prior Redux experience.
- Consider TCA first on greenfield SwiftUI.

## Decision examples

- Use this when the team wants Redux-style global state and already accepts ReSwift's ecosystem cost.
- Reject it for greenfield SwiftUI unless ReSwift compatibility is required; TCA is usually stronger.
- First safe slice: make reducers pure, then move async repository calls into middleware.

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

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://github.com/ReSwift/ReSwift | Global store subscription and reducer purity are the claims checked by the ReSwift example. | `examples/redux-reswift/` |

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/redux-reswift/`** —
a single `AppStore`, per-feature `State`/`Action`/`Reducer` triples, an async
middleware bridging the repository to dispatched actions, and SwiftUI views
subscribed to the store. `Domain` + `Data` follow `skills/ios-architect/references/reference-feature.md` (vendored per example).

> **Requires the `ReSwift` package**, wired in `examples/redux-reswift/Package.swift`.
> It builds and tests as a standalone SPM package.

Key things to notice:

- **One global `AppState`**, composed from feature sub-states; the store is the single source of truth and views read slices of it.
- **Reducers are pure `(State, Action) -> State`** — no async, no side effects; this is why they are the easiest tests in the whole bundle.
- **Side effects live in middleware** — `AsyncMiddleware` calls the repository and dispatches success/failure actions back into the store.
- **Views dispatch actions, never mutate state directly**; navigation is itself modeled as state in the store.


## Testing strategy

- Reducers get pure input/output tests: previous state + action -> next state.
- Middleware tests use fake services and assert dispatched follow-up actions in order.
- Cover failure actions and retry actions so middleware errors are reduced into state.
- Subscriber/presentation tests should prove the UI receives derived state without mutating the store.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert middleware dispatches loading and success actions and reducer creates loaded state. | Reducer test plus middleware fake |
| Repository failure | Assert failure action stores error state without mutating unrelated global state. | Reducer failure assertion |
| Subscriber update | Assert the subscriber receives only the selected state slice for list changes. | StoreSubscriber spy |
| Detail save | Assert update action changes the selected user in the store. | Reducer update assertion |
| Stale list response | Assert an older request ID cannot append rows after a newer refresh starts. | Reducer request-ID assertion |

## Concurrency and cancellation

- Reducers stay synchronous and side-effect-free; middleware owns async work.
- Model cancellation with request IDs, task handles, or middleware-scoped tokens so stale responses are ignored.
- Dispatch UI-facing state changes on the main actor/main queue.

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

## Failure modes

- Reducers run side effects.
- Global state becomes a dumping ground for local screen state.
- Views subscribe too broadly and rerender on unrelated changes.
- Middleware dispatches UI updates off the main actor.

## Review checklist

- Are reducers pure and deterministic?
- Are actions meaningful domain events, not UI widget names?
- Are subscriptions scoped to the smallest useful state slice?
- Does middleware handle errors and cancellation paths?
- Are observers unsubscribed on lifecycle end?
