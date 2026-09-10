# Uber RIBs — Example

`UserList` + `UserDetail` RIBs. Each RIB ships Builder, Component, Interactor, Router, ViewController.

> **Requires:** `RIBs` + `RxSwift`. Bridge `async/await` → `Single` via `Single.fromAsync` helper at the bottom of `UserListInteractor.swift`.

## Layout

```
Sources/
  App/AppDelegate.swift              // boots Root RIB tree
  Domain/  Data/
  RIBs/
    UserList/
      UserListBuilder.swift          // Builder + Component
      UserListInteractor.swift       // Interactor + Listener/Presentable protocols
      UserListRouter.swift           // ViewableRouter + Routing
      UserListViewController.swift   // ViewController + Presentable conformance
    UserDetail/
      UserDetailBuilder.swift
      UserDetailInteractor.swift
      UserDetailRouter.swift
      UserDetailViewController.swift
Tests/
  UserListInteractorTests.swift
  UserDetailInteractorTests.swift
  Support/
```

## Real-world refs

- uber/RIBs-iOS — https://github.com/uber/RIBs-iOS
- iOS Tutorial 1 — https://github.com/uber/RIBs-iOS/tree/main/tutorials/tutorial1
- iOS Tutorial 2 — https://github.com/uber/RIBs-iOS/tree/main/tutorials/tutorial2
- TicTacToe sample — https://github.com/uber/RIBs-iOS/tree/main/tutorials

## How testing works

Interactor is the testable unit. Mock the `Presentable` protocol (record `display(rows:)`, `displayError(_:)`). Stub repository via `FakeUserRepository`. Activate the RIB with `sut.activate()`, wait for the Rx scheduler to drain, assert on mock state. Router tested separately with mock builder.
