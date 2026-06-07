# MVP Example (UIKit, Passive View)

`UserList` + `UserDetail` using Model-View-Presenter. Presenter holds all presentation logic; ViewController is a passive view bound through a protocol.

## Layout

```
Sources/
  App/SceneDelegate.swift
  Domain/  Data/                          (shared)
  Features/
    UserList/
      UserListContracts.swift             // View + Presenter protocols + Row VM
      UserListPresenter.swift
      UserListViewController.swift
    UserDetail/
      UserDetailContracts.swift
      UserDetailPresenter.swift
      UserDetailViewController.swift
  Navigation/
    UserNavigator.swift
Tests/
  UserListPresenterTests.swift
  UserDetailPresenterTests.swift
  Support/                                (shared FakeUserRepository + fixtures)
```

## Real-world refs

- Martin Fowler, *Passive View*: https://martinfowler.com/eaaDev/PassiveScreen.html
- xmhafiz/ios-mvp: https://github.com/xmhafiz/ios-mvp
- nandawperdana/ios-mvp-swift: https://github.com/nandawperdana/ios-mvp-swift
- powerwolf543/Swift-MVP-Sample: https://github.com/powerwolf543/Swift-MVP-Sample

## How testing works

Presenter is the testable unit. Tests inject a `MockUserListView` (records `display(rows:)`, `displayLoading(_:)`, etc.) and a `FakeUserRepository`. Verifies the presenter calls the view in the right order and navigates via a spy `UserNavigating`.
