---
name: arch-mvc
description: Apple Cocoa MVC for iOS (UIKit). Use when implementing or refactoring against the default Apple sample-code pattern. Reject for production apps that will scale past 20 screens.
---

# Apple Cocoa MVC

**Source references:**
- Apple, *Model-View-Controller* (legacy archive) — https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Model-View-Controller/Model-View-Controller.html
- Apple sample, *DiffableDataSources* — https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource

## When to use

- Prototypes, throwaway apps.
- Solo dev, ≤ 20 screens, no networking-heavy flows.
- Apple sample code parity.
- Reject for any production app expected to scale.

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

## Reference implementation

The worked `UserList + UserDetail` feature lives in **`examples/mvc/`** — diffable-data-source
`UserListViewController`, a `UserDetailViewController` with save/dirty state, the `SceneDelegate`
composition root, and the limited VC-level tests. `Domain` + `Data` follow `skills/REFERENCE_FEATURE.md` (vendored per example).

Key things to notice:

- **The view controller is the SUT** — there is no layer between it and the repository, so the
  `load`/snapshot/navigation logic all lives in the VC. This is the bloat MVC is known for.
- **Pull-to-refresh + pagination + cancellation** are hand-wired in the VC (`loadTask` cancels on
  reassignment); MVVM would move this into a model.
- **VC testing is fragile** — `UserListViewControllerTests` forces `view` load and polls; this awkwardness
  is one of MVC's primary costs and the main reason to migrate.

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
