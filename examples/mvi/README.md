# MVI (SwiftUI) — Example

`UserList` + `UserDetail` using an explicit `State` + `Intent` store. SwiftUI views
render state and send intents; stores own async effects and repository access.

## Layout

```
Sources/
  App/UsersApp.swift
  Domain/  Data/
  Features/
    UserList/
      UserListStore.swift
      UserListView.swift
    UserDetail/
      UserDetailStore.swift
      UserDetailView.swift
Tests/
  UserListStoreTests.swift
  UserDetailStoreTests.swift
  Support/
```

## Real-world refs

- Apple, Observation — https://developer.apple.com/documentation/observation
- Point-Free, Composable Architecture concepts — https://github.com/pointfreeco/swift-composable-architecture
- Elm Architecture guide — https://guide.elm-lang.org/architecture/

## How testing works

Stores do not import `SwiftUI`. Tests send intents (`await store.dispatch(.onAppear)`)
and assert the resulting state. Fake repository injected via init. No SwiftUI runtime is required.
