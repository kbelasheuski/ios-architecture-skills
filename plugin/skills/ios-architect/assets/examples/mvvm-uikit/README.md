# MVVM (UIKit, Combine) — Example

`UserList` + `UserDetail` with `@Published` outputs + Combine bindings in the `UIViewController`.

## Layout

```
Sources/
  App/SceneDelegate.swift
  Domain/  Data/
  Features/
    UserList/
      UserListViewModel.swift
      UserListViewController.swift
    UserDetail/
      UserDetailViewModel.swift
      UserDetailViewController.swift
Tests/
  UserListViewModelTests.swift
  UserDetailViewModelTests.swift
  Support/
```

## Real-world refs

- Apple Combine documentation — https://developer.apple.com/documentation/combine
- Apple `UITableViewDiffableDataSource` — https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource

## How testing works

ViewModel is the testable unit (does not import UIKit). Tests subscribe to `@Published` outputs via Combine, drive inputs (`onAppear`, `didSelectRow`), assert emitted values. `PassthroughSubject` events asserted with a sink. `FakeUserRepository` injected through init.
