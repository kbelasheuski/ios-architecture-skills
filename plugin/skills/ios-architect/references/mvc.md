# Apple Cocoa MVC

**Source references:**
- Apple, *Model-View-Controller* (legacy archive) — https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Model-View-Controller/Model-View-Controller.html
- Apple sample, *DiffableDataSources* — https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource

## When to use

- Prototypes, throwaway apps.
- Solo dev, ≤ 20 screens, no networking-heavy flows.
- Apple sample code parity.
- Reject for any production app expected to scale.

## Decision examples

- Use this for a tiny UIKit screen where the ViewController is already the natural owner of table state and navigation.
- Reject it when the screen has paging, saving, retries, or shared state; move to MVVM-UIKit or MVP before adding more features.
- First safe slice: keep the VC public API stable, then extract repository calls and snapshot building behind tests.

## Folder structure

```
App/
  AppDelegate.swift
  SceneDelegate.swift
Models/
  User.swift
  UserRepository.swift
Views/
  UserCell.swift
Controllers/
  UserListViewController.swift
  UserDetailViewController.swift
```

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Model-View-Controller/Model-View-Controller.html | MVC role split is the baseline claim to verify before accepting controller-owned presentation logic. | `examples/mvc/` |

## Reference implementation

The worked `UserList + UserDetail` feature lives in **`examples/mvc/`** — diffable-data-source
`UserListViewController`, a `UserDetailViewController` with save/dirty state, the `SceneDelegate`
composition root, and the limited VC-level tests. `Domain` + `Data` follow `skills/ios-architect/references/reference-feature.md` (vendored per example).

Key things to notice:

- **The view controller is the SUT** — there is no layer between it and the repository, so the
  `load`/snapshot/navigation logic all lives in the VC. This is the bloat MVC is known for.
- **Pull-to-refresh + pagination + cancellation** are hand-wired in the VC (`loadTask` cancels on
  reassignment); MVVM would move this into a model.
- **VC testing is fragile** — `UserListViewControllerTests` forces `view` load and polls; this awkwardness
  is one of MVC's primary costs and the main reason to migrate.


## Testing strategy

- Treat MVC tests as characterization tests around existing behavior, not as proof that MVC is scalable.
- Use fake repositories at the composition root and assert visible VC behavior: rows, loading state, failure alerts, and navigation callbacks.
- Add tests before extracting MVVM/MVP seams so the migration preserves current screen behavior.
- Keep async VC tests deterministic by controlling repository completion instead of polling real time.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert the controller renders the first fake page and does not perform network work directly. | FakeUserRepository plus view-controller characterization test |
| Repository failure | Assert a repository error is converted into the screen error state without losing the previous selection. | FakeUserRepository error branch |
| Pull to refresh | Assert refresh resets pagination and asks the repository for page one exactly once. | FakeUserRepository fetchPageCalls |
| Detail save | Assert editing a user calls update and refreshes the visible detail state. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- Keep every UI mutation on `@MainActor`; repository calls may be async, but snapshot application and alerts stay on the main actor.
- Store view-owned `Task` handles and cancel them when a newer load starts or the view lifecycle makes the result stale.
- Guard delayed callbacks with `[weak self]` because MVC has no separate owner to absorb stale UI work.

## Pros / cons

**Pros**: Zero ceremony, framework-native, fastest greenfield.
**Cons**: Massive View Controller bloat is inevitable; weak unit testability; no layering.

## Corner cases

- `Task` started in `viewDidLoad` must `[weak self]` and cancel on `viewWillDisappear` if needed.
- `UIRefreshControl` is owned by `UITableViewController` via the `refreshControl` property — do not alloc inline.
- `UITableViewDiffableDataSource` requires items conform to `Hashable`; `User` does.
- `applySnapshot` on `@MainActor` only.
- State restoration: `encodeRestorableState`/`decodeRestorableState` — easy to forget; this VC currently doesn't implement them.

## Anti-patterns

- Networking inside `tableView(_:cellForRowAt:)`.
- Singleton repository (`UserRepository.shared`).
- Model state on the cell.
- 1000+ line view controllers.

## Migration hand-off

- To MVVM-UIKit: extract `users`/`page`/load logic into `UserListViewModel` (Combine); VC binds to `@Published` outputs.
- To MVVM-SwiftUI: same, then wrap VC in `UIHostingController` or rewrite VC as `View`.
- To MVVM-C: extract navigation calls into a `Coordinator`.

## Failure modes

- View controller grows into the only place where state, networking, navigation, and formatting live.
- Tests need to load UIKit views to verify basic business behavior.
- Reuse becomes copy/paste because no presentation boundary exists.
- Async tasks outlive the view controller or update stale UI.

## Review checklist

- Is MVC intentionally chosen for small scope, not by accident?
- Are dependencies injected instead of fetched from singletons?
- Are async tasks cancelled or guarded on view lifecycle changes?
- Is navigation isolated enough to migrate later?
- Is there a concrete migration path if this screen grows?
