# Coordinator — Example (SwiftUI NavigationStack)

`UserList` + `UserDetail` with a typed `AppCoordinator` over `NavigationStack(path:)`.
Screens expose navigation events as callbacks; the coordinator owns route state and deep-link parsing.

## Layout

```
Sources/
  App/UsersApp.swift
  Domain/  Data/
  Router/
    AppCoordinator.swift       // @Observable, holds [AppRoute]
    AppRoute.swift             // enum AppRoute: Hashable
  Features/
    UserList/
      UserListModel.swift
      UserListView.swift
    UserDetail/
      UserDetailModel.swift
      UserDetailView.swift
Tests/
  AppCoordinatorTests.swift
  UserListModelTests.swift
  Support/
```

## Real-world refs

- Soroush Khanlou, *Coordinators Redux* — https://khanlou.com/2015/10/coordinators-redux/
- erikdrobne/SwiftUICoordinator — https://github.com/erikdrobne/SwiftUICoordinator
- ml-opensource/SwiftUICoordinators — https://github.com/ml-opensource/SwiftUICoordinators
- Matteo Manferdini, *From broken to testable SwiftUI navigation* — https://matteomanferdini.com/mvvm-coordinator-swiftui/

## How testing works

Coordinator is plain `@Observable` with `path: [AppRoute]`, so tests assert route
mutations directly. Views integrate through `NavigationStack(path:)` and
`navigationDestination(for: AppRoute.self)`.
