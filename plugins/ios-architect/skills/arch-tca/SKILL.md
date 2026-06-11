---
name: arch-tca
description: The Composable Architecture (TCA) by Point-Free, SwiftUI-first. @Reducer + @ObservableState, Effect-driven, exhaustive testing via TestStore. Use for correctness-critical greenfield SwiftUI apps with capacity to absorb the learning curve.
---

# The Composable Architecture (TCA)

**Source references (study after reading this skill):**
- pointfreeco/swift-composable-architecture — https://github.com/pointfreeco/swift-composable-architecture
- CaseStudies — https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples/CaseStudies
- Tutorials — https://pointfreeco.github.io/swift-composable-architecture/main/tutorials/composablearchitecture
- TCA perf trade-offs (Karin Prater) — https://www.swiftyplace.com/blog/the-composable-architecture-performance

Code in this skill follows the canonical CaseStudies conventions: `@Reducer`, `@ObservableState`, `Reduce { state, action in switch action }`, `.ifLet`, `StackState`, `@DependencyClient`.

## When to use

- Greenfield SwiftUI apps, correctness-critical (payments, multi-step flows).
- At least one engineer who shipped TCA in production.
- Not for trivial screens (overkill).

## Folder structure

```
App/
  UsersApp.swift
  AppFeature.swift
Features/
  UserList/
    UserListFeature.swift
    UserListView.swift
  UserDetail/
    UserDetailFeature.swift
    UserDetailView.swift
Dependencies/
  UserClient.swift
Domain/
  User.swift
```

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/tca/`** —
`@Reducer` features with `@ObservableState`, a `UserClient` dependency, SwiftUI
views bound to `Store`, and `TestStore` tests. The shared `Domain` follows `plugins/ios-architect/skills/REFERENCE_FEATURE.md`; the example vendors its
own copy under `Sources/Domain`.

> **Requires the `swift-composable-architecture` package** (pointfreeco), wired in
> `examples/tca/Package.swift`. It builds and tests as a standalone SPM package —
> TCA uses macros, so pass `-skipMacroValidation` to `xcodebuild` in CLI/CI.

Key things to notice:

- **State is `@ObservableState`, actions are an enum**; the reducer is the only place state mutates. No `WithViewStore` — bindings come from the observed store directly (TCA 1.7+ style).
- **Side effects go through `@Dependency(\.userClient)`** — never a direct `URLSession` call inside the reducer; this is what makes `TestStore` exhaustive assertions possible.
- **Parent composes children** with `Scope` / `ifLet` / `forEach` and navigation via `@Presents` + `StackState`, not ad-hoc SwiftUI navigation.
- **Tests assert every state change and effect** through `TestStore`; an unasserted effect fails the test.

## Pros / cons

**Pros**
- Best-in-class testability via `TestStore` (exhaustive by default).
- Composable: `forEach`, `ifLet`, `Scope`, `Stack`.
- `@DependencyClient` macro + `@Dependency` make DI trivial.
- Time-travel debug, replayable actions.
- iOS 17 macros (`@Reducer`, `@ObservableState`) cut historical boilerplate.

**Cons**
- Steep learning curve.
- Enum/state explosion on large features without discipline.
- Perf footguns if `@ObservableState` skipped — see Karin Prater's analysis.
- Library lock-in.

## Corner cases

- `@ObservableState`: required; without it views observe whole state and re-render too widely.
- `StackState` + `StackActionOf<Feature>` + `.forEach(\.path, action: \.path) { Feature() }`: canonical drill-down pattern (CaseStudies uses `.ifLet` for optional, `.forEach` for stack).
- Parent reacts to child events via `.path(.element(id:_, action: .delegate(...)))`; this is the **delegate-action** convention — children expose effects to parents via a nested `Delegate` enum case rather than callbacks.
- `.cancellable(id: ..., cancelInFlight: true)` on every long-running effect.
- `testValue = UserClient()` — `@DependencyClient` makes calls XCTFail by default; override per test.
- `$store.scope(state: \.path, action: \.path)` is the SwiftUI navigation binding; `@Bindable var store` enables it.
- Use `IdentifiedArrayOf<User>` instead of `[User]` for diff-based updates.

## Anti-patterns

- `WithViewStore` on TCA ≥ 1.7 (replaced by `@ObservableState` + `@Bindable var store`).
- Mutating `State` inside `.run { ... }` (must round-trip via `send`).
- Long-running effects without `.cancellable(id:)`.
- Skipping the dependency client and calling `URLSession.shared` from a reducer.
- `Equatable State` with non-Equatable members (wrap or compute on demand).
- Deeply nested Reducers without `Scope` — flatten or split into modules.

## Migration hand-off

- To MVVM-SwiftUI: flatten Reducer → `@Observable` model; State props → properties; Action cases → methods.
- To Clean Architecture: keep TCA at Presentation; pull non-trivial business rules into Use Cases called from `Effect.run`.
- To Modular/TMA: each feature module exposes its `Reducer` type + `View` from its `Interface` target.

## Failure modes

- Effects mutate state directly instead of sending actions.
- Long-running effects have no cancellation ID.
- Dependency clients call live services in tests.
- Feature state grows because child reducers are not scoped.

## Review checklist

- Are all mutations inside reducers?
- Are effects cancellable and failure-aware?
- Does `TestStore` assert important state transitions and effects?
- Are dependencies injected through `@Dependency`?
- Are child features scoped instead of flattened into one reducer?
