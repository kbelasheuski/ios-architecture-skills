# MVVM (SwiftUI, @Observable) — Example

`UserList` + `UserDetail` using iOS 17 Observation framework. `@Observable @MainActor` model class owned via `@State` in the parent view.

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
- Apple Backyard Birds — https://developer.apple.com/documentation/swiftui/backyard-birds-sample
- Apple, *Migrating from ObservableObject to @Observable* — https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro
- Sarunw, *Observation Framework* — https://sarunw.com/posts/observation-framework-in-ios17/
- Antoine van der Lee, *MVVM in SwiftUI* — https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/

## How testing works

Model is a plain class — does not depend on `SwiftUI`. Tests drive the model directly (`await model.onAppear()`), assert on properties (`model.users`, `model.state`). Fake repository injected via init. No SwiftUI runtime required.
