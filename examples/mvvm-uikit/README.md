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

- thoughtbot/CombineViewModel — https://github.com/thoughtbot/CombineViewModel
- cristydobson/CryptoMarket_iOS_MVVM_Combine — https://github.com/cristydobson/CryptoMarket_iOS_MVVM_Combine
- Kous92/MVVM-UIKit-iOS-Combine-test — https://github.com/Kous92/MVVM-UIKit-iOS-Combine-test
- Antoine van der Lee, *MVVM* — https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/

## How testing works

ViewModel is the testable unit (does not import UIKit). Tests subscribe to `@Published` outputs via Combine, drive inputs (`onAppear`, `didSelectRow`), assert emitted values. `PassthroughSubject` events asserted with a sink. `FakeUserRepository` injected through init.
