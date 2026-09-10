# VIPER — Example (UIKit)

`UserList` + `UserDetail` modules, each split into View/Interactor/Presenter/Entities/Router/Protocols/Builder (canonical 7-file layout per module).

## Layout

```
Sources/
  App/SceneDelegate.swift
  Domain/  Data/
  Features/
    UserList/
      UserListProtocols.swift     // View, Presenting, Interactor, Router protocols
      UserListEntities.swift      // View-facing row VM
      UserListInteractor.swift    // wraps repository
      UserListPresenter.swift     // business state + view formatting
      UserListViewController.swift
      UserListRouter.swift
      UserListBuilder.swift       // wires the module
    UserDetail/
      ... (same 7 files)
Tests/
  UserListPresenterTests.swift
  UserDetailPresenterTests.swift
  Support/
```

## Real-world refs

- objc.io, *Architecting iOS Apps with VIPER* — https://www.objc.io/issues/13-architecture/viper/

## How testing works

Presenter is the testable unit. Mocks: `MockView` records `display(rows:)`, `displayLoading(_:)`. `StubInteractor` returns canned `UsersPage`. `SpyRouter` records navigation. Tests drive presenter inputs (`viewDidLoad`, `didSelectRow`) and assert on mock state.
