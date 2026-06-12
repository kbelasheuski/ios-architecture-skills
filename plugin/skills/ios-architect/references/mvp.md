# Model-View-Presenter (MVP)

**Source references:**
- Martin Fowler, *Passive View* — https://martinfowler.com/eaaDev/PassiveScreen.html
- Martin Fowler, *Supervising Controller* — https://martinfowler.com/eaaDev/SupervisingPresenter.html

## When to use

- UIKit team that wants testable presentation logic without Combine/Rx.
- iOS 13/14 codebases.
- Migration step from MVC where MVVM is too large a jump.

## Decision examples

- Use this when UIKit must stay, but business rendering should be testable without loading views.
- Reject it when the team wants reactive state binding; MVVM-UIKit will fit better.
- First safe slice: introduce `View` and `Presenter` protocols for one screen, then move load/save logic into the Presenter.

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

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://martinfowler.com/eaaDev/PassiveScreen.html | Passive View supports presenter-owned decisions with a view protocol as the seam. | `examples/mvp/` |

## Reference implementation

The full worked `UserList + UserDetail` feature lives in **`examples/mvp/`** —
per-screen `Contracts` (View + Presenter protocols), `Presenter`, `ViewController`,
a `UserNavigator` for routing, plus `Domain` + `Data` + test fakes that follow
`skills/ios-architect/references/reference-feature.md` (vendored per example). Key things to notice:

- **`UserList<X>Contracts.swift` defines both protocols** — the Presenter talks to the View only through its View protocol, which is what makes the Presenter testable without UIKit.
- **The Presenter is the unit under test**; the ViewController is mocked via the View protocol.
- **Navigation is explicit** through `UserNavigator`, not ad-hoc `present`/`pushViewController` from the ViewController.
- **The ViewController is passive** — it forwards user intent to the Presenter and renders whatever the Presenter pushes back.


## Testing strategy

- Unit test the Presenter with a fake View protocol and fake repository; do not launch UIKit for business behavior.
- Verify loading, empty, failure, retry, save, and navigation events through protocol calls.
- Keep one light ViewController smoke test only for wiring outlets/actions to Presenter inputs.
- Keep Presenter tests deterministic by driving async repository completions from fakes.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert presenter sends loading, content, and idle states to the passive view in order. | View spy plus FakeUserRepository |
| Repository failure | Assert presenter maps repository failure to a view error without UIKit dependencies. | View spy error assertion |
| User tap | Assert presenter asks the router/view seam to open detail for the selected user id. | Router spy or view spy |
| Detail save | Assert save calls repository update and emits the formatted detail view model. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- Presenter methods that update the View should run on `@MainActor`.
- Long-running work belongs in cancellable Presenter-owned tasks or injected use cases; the View should only forward lifecycle events.
- Cancel or ignore stale requests when the View detaches to avoid updating a released View protocol object.

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

## Failure modes

- Presenter starts retaining the view or UIKit objects.
- View protocol becomes a mirror of UIKit instead of user-facing render commands.
- Navigation leaks back into the ViewController.
- Presenter and ViewController both hold the same mutable state.

## Review checklist

- Is the View passive and easy to mock?
- Does the Presenter avoid UIKit imports?
- Are async failures rendered through View protocol methods?
- Is navigation delegated to a Navigator or Coordinator?
- Do tests exercise Presenter behavior without launching UI?
