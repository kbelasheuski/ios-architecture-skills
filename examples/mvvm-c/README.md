# MVVM-C — Example (SwiftUI Router variant)

`UserList` + `UserDetail` with a typed `AppRouter` (`@Observable`) over `NavigationStack(path:)`. The list `Model` exposes a selection callback that the App composes into a `router.push(.userDetail(id:))`.

## Layout

```
Sources/
  App/UsersApp.swift
  Domain/  Data/
  Router/
    AppRouter.swift            // @Observable, holds [Route]
    Route.swift                 // enum Route: Hashable
  Features/
    UserList/
      UserListModel.swift
      UserListView.swift
    UserDetail/
      UserDetailModel.swift
      UserDetailView.swift
Tests/
  AppRouterTests.swift
  UserListModelTests.swift
  Support/
```

## Real-world refs

- Soroush Khanlou, *Coordinators Redux* — https://khanlou.com/2015/10/coordinators-redux/
- erikdrobne/SwiftUICoordinator — https://github.com/erikdrobne/SwiftUICoordinator
- ml-opensource/SwiftUICoordinators — https://github.com/ml-opensource/SwiftUICoordinators
- Matteo Manferdini, *From broken to testable SwiftUI navigation* — https://matteomanferdini.com/mvvm-coordinator-swiftui/

## How testing works

Router is plain `@Observable` w/ `path: [Route]` — directly testable: assert path mutations. Models are testable as in `arch-mvvm-swiftui`. Views integrate via `NavigationStack(path: $router.path)` + `navigationDestination(for: Route.self)`.
