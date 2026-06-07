---
name: arch-mvp
description: Model-View-Presenter for UIKit. Passive View + Presenter holding presentation logic. Use when migrating MVC towards testability without taking on Combine/Rx.
---

# Model-View-Presenter (MVP)

**Source references:**
- Martin Fowler, *Passive View* — https://martinfowler.com/eaaDev/PassiveScreen.html
- Martin Fowler, *Supervising Controller* — https://martinfowler.com/eaaDev/SupervisingPresenter.html

## When to use

- UIKit team that wants testable presentation logic without Combine/Rx.
- iOS 13/14 codebases.
- Migration step from MVC where MVVM is too large a jump.

## Folder structure

```
Features/
  UserList/
    UserListViewController.swift
    UserListPresenter.swift
    UserListContracts.swift
  UserDetail/
    UserDetailViewController.swift
    UserDetailPresenter.swift
    UserDetailContracts.swift
Models/
  User.swift
  UserRepository.swift
Navigation/
  UserNavigator.swift
```

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/mvp/`** —
per-screen `Contracts` (View + Presenter protocols), `Presenter`, `ViewController`,
a `UserNavigator` for routing, plus `Domain` + `Data` + test fakes that follow
`skills/REFERENCE_FEATURE.md` (vendored per example). Key things to notice:

- **`UserList<X>Contracts.swift` defines both protocols** — the Presenter talks to the View only through its View protocol, which is what makes the Presenter testable without UIKit.
- **The Presenter is the unit under test**; the ViewController is mocked via the View protocol.
- **Navigation is explicit** through `UserNavigator`, not ad-hoc `present`/`pushViewController` from the ViewController.
- **The ViewController is passive** — it forwards user intent to the Presenter and renders whatever the Presenter pushes back.

## Pros / cons

**Pros**: Presenter testable (no UIKit import), works on legacy iOS, simple.
**Cons**: 1:1 Presenter↔View coupling forces dual edits; navigation undefined (use Navigator/Coordinator); protocol boilerplate per screen.

## Corner cases

- `weak var view`; never strong from Presenter.
- `@MainActor` on View protocol so Presenter calls are main-thread safe.
- `bind(presenter:)` must run before `viewDidLoad`; do it at construction in the Navigator.
- Reentrancy: load while load — guard with the `loading` state.

## Anti-patterns

- View holds `User` models.
- Closures from View to Presenter for navigation (use Navigator).
- Presenter imports `UIKit`.

## Migration hand-off

- To MVVM-UIKit: rename Presenter→ViewModel, replace View-protocol push with `@Published` outputs + Combine bindings.
- To MVVM-SwiftUI: same, plus host via `UIHostingController` during transition.
