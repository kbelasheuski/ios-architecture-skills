---
name: arch-mvvm-swiftui
description: MVVM for SwiftUI using the iOS 17 Observation framework (@Observable). Default for medium SwiftUI apps. Use when implementing or refactoring SwiftUI screens with non-trivial presentation logic.
---

# MVVM (SwiftUI, `@Observable`)

**Source references (study after reading this skill):**
- Apple Scrumdinger sample — https://developer.apple.com/tutorials/app-dev-training/getting-started-with-scrumdinger
- Apple Backyard Birds sample — https://developer.apple.com/documentation/swiftui/backyard-birds-sample
- Antoine van der Lee, *MVVM in SwiftUI* — https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/
- Sarunw, *Observation Framework in iOS 17* — https://sarunw.com/posts/observation-framework-in-ios17/

## When to use

- SwiftUI on iOS 17+.
- Medium project, 20–80 screens.
- Per-property invalidation needed (perf-sensitive lists, charts).

## Folder structure

```
App/AppEntry.swift
Features/
  UserList/
    UserListView.swift
    UserListModel.swift
  UserDetail/
    UserDetailView.swift
    UserDetailModel.swift
Domain/User.swift
Domain/UserRepository.swift
Data/LiveUserRepository.swift
```

## Reference implementation

The full worked `UserList + UserDetail` feature lives in
**`examples/mvvm-swiftui/`** — `@Observable @MainActor` models, SwiftUI Views,
the app entry point, and model XCTest. `Domain` + `Data` + test fakes follow
`plugins/ios-architect/skills/REFERENCE_FEATURE.md` (vendored per example). Key things to
notice:

- **The model is `@Observable @MainActor`**, owned by the View via `@State` and injected into child views as a plain property — no `ObservableObject`/`@Published`.
- **Paging, refresh, and error state live in the model**, exposed as `private(set)` properties; the View only sends intent (`viewDidLoad`, `didPullToRefresh`, `didLoadNextPageIfNeeded`).
- **Navigation is a closure passed into the model**, not a reference the model holds — keeps the model UIKit/SwiftUI-free and testable.
- **Models never import SwiftUI**; they depend on the `UserRepository` protocol only.

## Combine variant

Use `examples/mvvm-swiftui-combine/` when the project already standardises on
`ObservableObject`, `@Published`, or Combine bindings. Keep the same boundaries:
the View owns the model with `@StateObject`, the model stays `@MainActor`, and
repositories are injected through init. If the feature is mainly a stream pipeline
(search, live feed, debounce, latest request wins), switch to `arch-reactive`.

## Pros / cons

**Pros**
- Per-property invalidation via Observation framework.
- Clear ownership: `@State` owns model, plain property injects child models.
- Idiomatic SwiftUI; no Combine glue.
- Easy unit tests (`@MainActor` async XCTest).

**Cons**
- Debate vs MV pattern: for trivial screens VM duplicates SwiftUI's own state.
- Navigation needs separate strategy at scale — see `arch-mvvm-c` (Router variant).

## Corner cases

- `@State private var model` with `_model = State(initialValue: ...)` is the correct pattern to inject a built model from parent without recreating on rerender.
- Use `.task` (not `.onAppear { Task { ... } }`) so cancellation fires on disappear.
- `@MainActor` on `@Observable` class avoids Swift 6 strict-concurrency warnings when async paths mutate state.
- `loadNextPageIfNeeded` threshold ≥ `count - 3` to prefetch before reaching the end without race-firing while loading.
- For previews and tests, inject `FakeUserRepository`; never use a real network.
- `NavigationStack` middle-removal limit: `path.removeLast(k)` only. For arbitrary removal, recreate the path.

## Anti-patterns

- Accidental `@StateObject` / `@ObservedObject` in new iOS 17 code. Use `@State` + `@Observable` unless this is the deliberate Combine variant.
- `import SwiftUI` inside the model.
- Business logic in the View body.
- Holding `@State` for child models in the wrong owner (causes recreation on parent rerender).
- `Task { ... }` in `.onAppear` instead of `.task`.

## Migration hand-off

- To MVVM-C: introduce `Router` (see `arch-mvvm-c`).
- To TCA: see `migrator` primitive P9 — map model properties to `State`, methods to `Action`, async work to `Effect`.
- To Clean Architecture: pull repository contract into a `Domain` module, inject use-cases instead of repositories.

## Failure modes

- Model imports SwiftUI and starts owning view concerns.
- Views hold business state because the model feels too small.
- Child models are recreated on parent rerender.
- Navigation state is split between views and models.

## Review checklist

- Is the model `@Observable @MainActor` and SwiftUI-free?
- Are dependencies injected through init?
- Does `.task` own lifecycle-driven async work?
- Are loading, empty, failure, and cancellation paths visible in state?
- Is navigation handed to a router/coordinator when it grows?
