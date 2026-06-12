# Redux / ReSwift — Example

`UserList` + `UserDetail` over a single global store, pure reducers, async via middleware.

> **Requires:** `ReSwift` 6.x.

## Layout

```
Sources/
  App/
    UsersApp.swift
    Store/
      AppState.swift
      AppAction.swift
      AppReducer.swift
      AppStore.swift
  Domain/  Data/
  Middleware/
    AsyncMiddleware.swift
  Features/
    UserList/
      UserListState.swift
      UserListAction.swift
      UserListReducer.swift
      UserListView.swift
      UserListObserver.swift
    UserDetail/
      UserDetailState.swift
      UserDetailAction.swift
      UserDetailReducer.swift
      UserDetailView.swift
      UserDetailObserver.swift
Tests/
  UserListReducerTests.swift
  UserDetailReducerTests.swift
  Support/
```

## Real-world refs

- ReSwift/ReSwift — https://github.com/ReSwift/ReSwift
- Dan Abramov, *Three Principles* — https://redux.js.org/understanding/thinking-in-redux/three-principles

## How testing works

Reducers are pure functions over `Equatable` state — trivial to test. Drive: `next = reducer(action: ..., state: ...)`. Middleware tested separately by injecting a fake dispatch + `FakeUserRepository`.
