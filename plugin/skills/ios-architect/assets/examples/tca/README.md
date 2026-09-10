# The Composable Architecture (TCA) — Example

`UserList` + `UserDetail` with `@Reducer`, `@ObservableState`, `StackState`, exhaustive `TestStore`.

> **Requires:** `swift-composable-architecture` ≥ 1.7 (pinned to iOS 17 conventions: `@ObservableState`, `@Bindable var store`).

## Layout

```
Sources/
  App/UsersApp.swift
  Domain/  Data/
  Dependencies/
    UserClient.swift                  // @DependencyClient over UserRepository
  Features/
    UserList/
      UserListFeature.swift           // @Reducer
      UserListView.swift
    UserDetail/
      UserDetailFeature.swift
      UserDetailView.swift
Tests/
  UserListFeatureTests.swift
  UserDetailFeatureTests.swift
  Support/
```

## Real-world refs

- pointfreeco/swift-composable-architecture — https://github.com/pointfreeco/swift-composable-architecture
- CaseStudies — https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples/CaseStudies
- TCA tutorials — https://pointfreeco.github.io/swift-composable-architecture/main/tutorials/composablearchitecture

## How testing works

`TestStore` exhaustively asserts every state mutation and effect. Inject deterministic dependency closures (`$0.userClient.fetchUsers = { _ in ... }`). For `dismiss`, override `$0.dismiss = DismissEffect { }`. Parent observes child via delegate-action pattern (`.delegate(.didSave(saved))`).
