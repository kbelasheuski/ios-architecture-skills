---
name: arch-ribs
description: Uber RIBs (Router-Interactor-Builder). Hierarchical RIB tree, RxSwift-driven, Builder/Component DI. Use only at Uber-scale teams (≥30 iOS engineers) with deeply nested state. Reject otherwise.
---

# RIBs (Uber)

**Source references:**
- uber/RIBs — https://github.com/uber/RIBs
- iOS Tutorial 1 — https://github.com/uber/RIBs/wiki/iOS-Tutorial-1
- iOS Tutorial 2 (composing RIBs) — https://github.com/uber/RIBs/wiki/iOS-Tutorial-2
- TicTacToe sample sources — https://github.com/uber/RIBs/tree/main/ios/tutorials

Conventions match the TicTacToe tutorial: `Builder` constructs the RIB; `Buildable` is the protocol the parent depends on; `Component<Dep>` carries dependencies; `Router : ViewableRouter` (or `Router`); `Interactor : PresentableInteractor`. Listener interfaces flow events upward.

## When to use

- iOS team ≥ 30 engineers, deeply nested persistent state.
- Cross-platform parity with Android RIBs target.
- Reject otherwise — cost not justified.

## Folder structure

```
App/
  AppDelegate.swift
RIBs/
  Root/
    RootBuilder.swift
    RootComponent.swift
    RootInteractor.swift
    RootRouter.swift
    RootViewController.swift
  UserList/
    UserListBuilder.swift
    UserListComponent.swift
    UserListInteractor.swift
    UserListRouter.swift
    UserListViewController.swift
  UserDetail/
    UserDetailBuilder.swift
    UserDetailComponent.swift
    UserDetailInteractor.swift
    UserDetailRouter.swift
    UserDetailViewController.swift
```

## Reference implementation

The worked `Root → UserList → UserDetail` RIB tree lives in **`examples/ribs/`** —
Builder/Component/Interactor/Router/ViewController per RIB, with the Root wiring
UserList as its initial child. `Domain` + `Data` follow `skills/REFERENCE_FEATURE.md` (vendored per example).

> **Requires Uber's `RIBs` framework + `RxSwift`.** RIBs is not distributed via
> SPM, so this example is readable reference code, not a standalone-buildable
> package. Use it to study the tree wiring, not as a drop-in.

Key things to notice:

- **Each RIB is a Builder + Component + Interactor + Router (+ optional ViewController).** `ViewableRouting` RIBs own a VC; logic-only RIBs do not.
- **The Interactor holds business logic and the listener protocol** to its parent; children talk up through listener protocols, parents attach/detach children through the Router.
- **The Component is the DI scope** — it provides dependencies down the tree and is the only place a RIB constructs its children's dependencies.
- **Navigation = attaching/detaching child RIBs** via the Router, not pushing view controllers directly.

## Pros / cons

**Pros**: Proven at hundreds-of-engineers scale; feature parallelism via the RIB tree; codegen tooling.
**Cons**: Highest boilerplate of any pattern (~6 files per RIB); RxSwift dependency; tiny community; very steep onboarding; poor SwiftUI story.

## Corner cases

- `attachChild` / `detachChild` is mandatory; missing detach leaks the subtree.
- Listener (upward) vs Presentable (downward) — never cross the wires.
- `Component` inheritance carries deps; design the dep graph up front.
- Rx ↔ async/await bridge via `Single.fromAsync` helper; do not block.
- Cross-platform parity: keep Interactor Rx-only, never `UIKit`.

## Anti-patterns

- Inline `pushViewController` outside the Router.
- Strong Listener reference (forgot `weak`).
- Skipping Builders.
- SwiftUI-only RIB implementations.
- Mixing async/await + Rx without the bridge → leaks.

## Migration hand-off

- To MVVM-C: Interactor → ViewModel; Router → Coordinator; drop Rx for Combine; drop Builder/Component for a small DI container.
- To TCA: P9 per RIB; tree → composed reducers; Rx → async/await + Effects.
- To Modular/TMA: each RIB folder becomes a Tuist/SPM module exposing its Builder.
