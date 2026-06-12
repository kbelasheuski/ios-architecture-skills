# Clean Swift (VIP) — Example (UIKit)

`UserList` + `UserDetail` scenes with strict V→I→P→V cycle. Per-boundary `Request`/`Response`/`ViewModel` structs in `UserListModels.swift`. `Worker` wraps the repository. `Configurator` wires the scene.

## Layout

```
Sources/
  App/SceneDelegate.swift
  Domain/  Data/
  Scenes/
    UserList/
      UserListModels.swift        // Request/Response/ViewModel namespaced
      UserListViewController.swift
      UserListInteractor.swift
      UserListPresenter.swift
      UserListRouter.swift
      UserListWorker.swift
      UserListConfigurator.swift
    UserDetail/
      ... (same 7 files)
Tests/
  UserListInteractorTests.swift
  UserListPresenterTests.swift
  Support/
```

## Real-world refs

- Raymond Law, *Clean Swift* — https://clean-swift.com/

## How testing works

Interactor and Presenter are the testable units. Tests use `SpyPresenter` to assert what Interactor emits, and `MockDisplayLogic` to assert what Presenter sends to the view. Each cycle leg tested in isolation: `interactor.fetchUsers` → `SpyPresenter.received`, `presenter.present` → `MockDisplay.lastViewModel`.
