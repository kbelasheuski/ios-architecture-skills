---
name: arch-coordinator
description: Coordinator architecture for iOS navigation. Use when navigation, deep links, reusable flows, or UIKit/SwiftUI routing should be decoupled from views and view models.
---

# Coordinator

Coordinator is a navigation layer, not a full app architecture. Pair it with
MVVM, MVP, Clean Architecture, TCA, or another presentation pattern.

## When To Use

- View controllers or views currently push/present directly.
- Deep links need one owner.
- The same screen appears in several flows.
- Navigation tests matter.
- UIKit and SwiftUI flows need to coexist during migration.

## Structure

SwiftUI:

```
Router/
  AppCoordinator.swift       // owns [AppRoute]
  AppRoute.swift             // Hashable route enum
Features/
  UserList/UserListView.swift
  UserDetail/UserDetailView.swift
```

UIKit:

```
Navigation/
  AppCoordinator.swift       // owns UINavigationController
  UserFlowCoordinator.swift
```

The buildable SwiftUI reference is `examples/coordinator/`.

## Rules

- Views and ViewModels emit navigation events; they do not own route state.
- SwiftUI coordinators use value routes with `NavigationStack(path:)`.
- UIKit coordinators own `UINavigationController` and child coordinators.
- Deep links parse into routes before touching UI.
- Keep repositories and services out of coordinators.

## Failure Modes

- Coordinator becomes a dependency container for the whole app.
- ViewModel holds the concrete coordinator and calls many route methods.
- UIKit child coordinator is never released after finish.
- SwiftUI path is split across multiple unrelated owners.
- Deep-link parsing happens inside views.

## Review Checklist

- Is there one owner for each navigation flow?
- Are routes typed values, not stringly typed screens?
- Do screens expose callbacks or route intents instead of pushing directly?
- Are child coordinators retained and released intentionally?
- Are deep links covered by unit tests?

## Migration Hand-Off

- From MVC/MVVM: extract push/present calls into a coordinator first.
- To TCA: route state can become `StackState`.
- To Modular/TMA: expose only route factories or feature interfaces across module boundaries.
