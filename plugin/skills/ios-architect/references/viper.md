# VIPER

**Source references:**
- griddynamics/VIPER-SWIFT (fork of mutualmobile/VIPER-SWIFT, MIT) — https://github.com/griddynamics/VIPER-SWIFT
- objc.io, *Architecting iOS Apps with VIPER* (original article) — https://www.objc.io/issues/13-architecture/viper/

Conventions match the mutualmobile/griddynamics layout (Wireframe/Module/View/Interactor/Presenter).

## When to use

- Large UIKit codebases (≥ 80 screens) with multi-team ownership.
- Regulated domains where per-layer review trails matter.
- Reject for SwiftUI-first; reject for teams < 5.

## Decision examples

- Use this for large UIKit modules where role boundaries are more valuable than ceremony cost.
- Reject it for small teams or SwiftUI-first features; MVVM or Clean Swift is usually cheaper.
- First safe slice: split Presenter and Interactor first, then move route construction into Router/Builder.

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

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://www.objc.io/issues/13-architecture/viper/ | VIPER's view/interactor/presenter/router split is only useful when the module boundary is worth the file overhead. | `examples/viper/` |

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/viper/`** —
the seven files per module (Protocols, Entities, Interactor, Presenter,
ViewController, Router, Builder), with `Domain` + `Data` + test fakes that follow
`skills/ios-architect/references/reference-feature.md` (vendored per example). Key things to notice:

- **`UserList<X>Protocols.swift` is the contract hub** — View↔Presenter↔Interactor↔Router protocols in one file; everything else conforms to it.
- **The Presenter is the unit under test** — it holds no UIKit; the ViewController is a thin `view` conforming to the View protocol and is mocked in tests.
- **The Router owns navigation; the Builder assembles the module** — the ViewController never instantiates the next module itself.
- **Interactor is async and UI-free** — it talks to the repository and hands data back to the Presenter, which formats it for the View.


## Testing strategy

- Presenter tests should use View and Router spies; Interactor tests should use fake repositories/use cases.
- Cover Interactor failure mapping before the Presenter formats user-facing error state.
- Router/Builder tests should verify module assembly and route wiring without business logic.
- Add characterization tests before splitting a legacy massive module into VIPER files.
- Keep Presenter and Interactor tests deterministic with fake gateways and explicit output spies.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert Interactor fetches data and Presenter formats the list view model. | Interactor fake plus view spy |
| Repository failure | Assert Presenter maps failure response into a view error model. | View spy error assertion |
| User tap | Assert Router receives the detail navigation request and Presenter stays UI-agnostic. | Router spy |
| Detail save | Assert Interactor calls update and Presenter emits the updated detail model. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- Interactors own async work and report results back to the Presenter on the main actor.
- Presenters should not start detached tasks or call networking directly.
- Router transitions stay main-actor and should not retain modules after the flow ends.

## Pros / cons

**Pros**: Highest per-module testability; parallel team work; mechanical file-level ownership.
**Cons**: Six core roles per screen plus contracts/assembly; heavy boilerplate; steep onboarding; poor SwiftUI fit; LLM-agent context inflated by cross-file action chains.

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
