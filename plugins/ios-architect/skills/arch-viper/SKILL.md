---
name: arch-viper
description: VIPER for UIKit. Five-component module per screen — View, Interactor, Presenter, Entity, Router — plus Builder. Use for large UIKit codebases with multi-team ownership or regulated domains. Reject for SwiftUI-first and small teams.
---

# VIPER

**Source references:**
- griddynamics/VIPER-SWIFT (fork of mutualmobile/VIPER-SWIFT, MIT) — https://github.com/griddynamics/VIPER-SWIFT
- objc.io, *Architecting iOS Apps with VIPER* (original article) — https://www.objc.io/issues/13-architecture/viper/

Conventions match the mutualmobile/griddynamics layout (Wireframe/Module/View/Interactor/Presenter).

## When to use

- Large UIKit codebases (≥ 80 screens) with multi-team ownership.
- Regulated domains where per-layer review trails matter.
- Reject for SwiftUI-first; reject for teams < 5.

## Folder structure

```
Features/
  UserList/
    UserListProtocols.swift
    UserListEntities.swift
    UserListInteractor.swift
    UserListPresenter.swift
    UserListViewController.swift
    UserListRouter.swift
    UserListBuilder.swift
  UserDetail/
    ... (same six files)
```

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/viper/`** —
the seven files per module (Protocols, Entities, Interactor, Presenter,
ViewController, Router, Builder), with `Domain` + `Data` + test fakes that follow
`plugins/ios-architect/skills/REFERENCE_FEATURE.md` (vendored per example). Key things to notice:

- **`UserList<X>Protocols.swift` is the contract hub** — View↔Presenter↔Interactor↔Router protocols in one file; everything else conforms to it.
- **The Presenter is the unit under test** — it holds no UIKit; the ViewController is a thin `view` conforming to the View protocol and is mocked in tests.
- **The Router owns navigation; the Builder assembles the module** — the ViewController never instantiates the next module itself.
- **Interactor is async and UI-free** — it talks to the repository and hands data back to the Presenter, which formats it for the View.

## Pros / cons

**Pros**: Highest per-module testability; parallel team work; mechanical file-level ownership.
**Cons**: 6 files per screen; heavy boilerplate; steep onboarding; poor SwiftUI fit; LLM-agent context inflated by cross-file action chains.

## Corner cases

- `weak var view` in Presenter; `weak var viewController` in Router.
- Entities (`UserListRowEntity`) are View-facing DTOs; never leak `User` to the View.
- Builder is the only public symbol per module.
- Async + Interactor: only Interactor imports networking; Presenter only awaits.
- For modules in separate SPM packages, Builder must be `public`; Presenter/Interactor/Router can stay internal.

## Anti-patterns

- Presenter importing UIKit (for `UIImage`/`UIColor` — use string/data wrappers).
- Router calling Presenter (Router only knows the View hierarchy and other Builders).
- Skipping the Builder and constructing modules inline in Router.
- Entities holding `User` domain model directly.

## Migration hand-off

- To MVVM-UIKit: collapse Interactor + Presenter → ViewModel; Router → Coordinator; drop Entities (Domain model directly).
- To Clean Architecture: Interactor's rules → Use Cases (Domain); Presenter → VM (Presentation); Router → Coordinator.
- To TCA: Presenter → Reducer; Interactor calls → Dependency client; Router → `StackState` Path reducer.

## Failure modes

- Protocols exist, but modules still call concrete types directly.
- Presenter starts doing Interactor work or importing UIKit.
- Router owns business decisions instead of navigation.
- Builders are skipped and composition spreads across the app.

## Review checklist

- Is each VIPER role doing one job?
- Is the Builder the only public module constructor?
- Does Presenter remain UI-framework-free?
- Are Interactor async failures mapped before reaching the View?
- Are Router and Presenter kept separate?
