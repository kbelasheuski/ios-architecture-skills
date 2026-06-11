---
name: arch-mvi
description: MVI for iOS apps. Use for SwiftUI or UIKit features that need explicit State + Intent, deterministic transitions, and unidirectional flow without adopting TCA.
---

# MVI

Use MVI when the screen behaves like a small state machine and the team wants
strict unidirectional flow without a framework dependency.

## When To Use

- SwiftUI or UIKit feature with several loading, error, editing, and navigation states.
- You need deterministic state transitions that are easy to test.
- TCA would be useful, but the team does not want the dependency or learning curve.

Avoid it for simple read-only screens; MVVM is easier there.

## Structure

```
Features/UserList/
  UserListStore.swift       // State + Intent + dispatch
  UserListView.swift        // renders State, sends Intent
Domain/
  User.swift
  UserRepository.swift
Data/
  LiveUserRepository.swift
```

The buildable reference is `examples/mvi/`.

## Rules

- State is a value type. Views read it; only the Store mutates it.
- Intents are user or lifecycle events: `onAppear`, `refresh`, `save`, `rowTapped`.
- Effects run inside the Store and feed back through state changes.
- Views do not call repositories, use cases, or services.
- Navigation is either an intent delegated to a parent, or a separate Coordinator.

## Failure Modes

- Store turns into a service locator and constructs dependencies itself.
- Views mutate state directly instead of sending intents.
- Async work writes partial state without a loading or failure transition.
- One large app-wide store is used for every feature.
- Intents encode UI widgets instead of user meaning.

## Review Checklist

- Does every state mutation happen inside `dispatch` or a reducer-like helper?
- Are success, empty, loading, cancellation, and failure states testable?
- Does the view render state without business logic?
- Are dependencies injected through init?
- Is navigation owned outside the Store unless it is local value state?

## Migration Hand-Off

- To TCA: map `State` to reducer state, `Intent` to `Action`, and async work to `Effect`.
- To MVVM: collapse intents into model methods when the state machine is no longer needed.
- To Coordinator: move route changes out of the Store and expose route intents.
