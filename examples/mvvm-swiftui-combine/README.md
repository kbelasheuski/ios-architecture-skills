# MVVM (SwiftUI + Combine) — Example

`UserList` + `UserDetail` using `ObservableObject`, `@Published`, and SwiftUI bindings.
The model stays `@MainActor`; views own it with `@StateObject`.

## Layout

```
Sources/
  App/UsersApp.swift
  Domain/  Data/
  Features/
    UserList/
      UserListModel.swift
      UserListView.swift
    UserDetail/
      UserDetailModel.swift
      UserDetailView.swift
Tests/
  UserListModelTests.swift
  UserDetailModelTests.swift
  Support/
```

## Real-world refs

- Apple Scrumdinger sample — https://developer.apple.com/tutorials/app-dev-training
- Apple, *Managing model data in your app* — https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app
- Apple, Combine — https://developer.apple.com/documentation/combine

## How testing works

Models do not import `SwiftUI`. Tests drive the model directly (`await model.onAppear()`),
assert on published state, and inject a fake repository through init. No SwiftUI runtime is required.
