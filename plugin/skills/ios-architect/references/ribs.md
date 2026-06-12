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

## Decision examples

- Use this only for very large teams or nested state trees where RIBs tooling and ceremony pay off.
- Reject it for most SwiftUI apps and small UIKit teams; MVVM-C, TCA, or Modular/TMA is lighter.
- First safe slice: model one parent-child RIB pair and prove attach/detach lifecycle tests.

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

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://github.com/uber/RIBs | RIBs requires router/interactor/component boundaries; the local example is reference-only, not proof of Uber-scale payoff. | `examples/ribs/` |

## Reference implementation

The worked `Root → UserList → UserDetail` RIB tree lives in **`examples/ribs/`** —
Builder/Component/Interactor/Router/ViewController per RIB, with the Root wiring
UserList as its initial child. `Domain` + `Data` follow `skills/ios-architect/references/reference-feature.md` (vendored per example).

> **Requires Uber's `RIBs` framework + `RxSwift`.** RIBs is not distributed via
> SPM, so this example is readable reference code, not a standalone-buildable
> package. Use it to study the tree wiring, not as a drop-in.

Key things to notice:

- **Each RIB is a Builder + Component + Interactor + Router (+ optional ViewController).** `ViewableRouting` RIBs own a VC; logic-only RIBs do not.
- **The Interactor holds business logic and the listener protocol** to its parent; children talk up through listener protocols, parents attach/detach children through the Router.
- **The Component is the DI scope** — it provides dependencies down the tree and is the only place a RIB constructs its children's dependencies.
- **Navigation = attaching/detaching child RIBs** via the Router, not pushing view controllers directly.


## Testing strategy

- Test Interactors with fake listeners and dependencies; assert business state and child routing requests.
- Test Routers for attach/detach paths and Builder assembly, especially around optional children.
- Add integration tests around parent-child contracts because most RIB failures are lifecycle or dependency-scope bugs.
- Keep Interactor tests deterministic by controlling listener callbacks and dependency outputs.
- Cover dependency failure and listener error paths before adding integration-level RIB tests.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert Interactor asks dependency for users and Presenter/View receives loaded state. | Dependency fake plus listener spy |
| Repository failure | Assert failure is handled inside the RIB boundary and does not escape as navigation. | Listener spy no-route assertion |
| Attach child | Assert Router builds and attaches the detail child for the selected user. | Builder fake plus router assertion |
| Detail save | Assert Interactor update informs its listener after repository success. | Dependency fake updateCalls |

## Concurrency and cancellation

- Interactors own business async work and cancel it in lifecycle hooks when the RIB detaches.
- Routers should not perform async business work; they attach/detach and coordinate view hierarchy changes on the main actor.
- Dependency scopes should make it obvious which tasks and services die with each child RIB.

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

## Failure modes

- Child RIBs attach but never detach.
- Listener references are strong.
- Components leak dependencies sideways instead of down the tree.
- Router performs business logic because Interactor boundaries are unclear.

## Review checklist

- Does each RIB have clear Builder, Component, Interactor, Router, and View roles?
- Are child attach/detach paths tested or easy to reason about?
- Are listener references weak?
- Are dependencies provided by Components, not globals?
- Is Rx bridged safely when async/await is introduced?
