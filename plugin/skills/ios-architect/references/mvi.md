# MVI

Use MVI when the screen behaves like a small state machine and the team wants
strict unidirectional flow without a framework dependency.

## When To Use

- SwiftUI or UIKit feature with several loading, error, editing, and navigation states.
- You need deterministic state transitions that are easy to test.
- TCA would be useful, but the team does not want the dependency or learning curve.

Avoid it for simple read-only screens; MVVM is easier there.

## Decision examples

- Use this when one feature has many visible states and user intents must be serialized.
- Reject it for simple forms where MVVM is enough.
- First safe slice: define `State`, `Intent`, and one Store reducer for the no-network path, then add effects.

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


## Testing strategy

- Test the store as a deterministic state machine: send intents, assert every state transition, including failure state, then assert emitted route intents.
- Inject fake repositories and clocks so loading, retry, cancellation, and debounce behavior has no sleeps.
- Keep view tests shallow: the view should only render `State` and send `Intent`.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert dispatching appear intent produces loading and loaded states in order. | Store test plus FakeUserRepository |
| Repository failure | Assert failure intent path stores an error state without mutating loaded items. | FakeUserRepository error branch |
| Pull to refresh | Assert refresh intent resets page state before loading the first page. | Store state assertion |
| Detail save | Assert save intent records updated user and returns to non-saving state. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- Serialize `dispatch` on the main actor or a dedicated store executor; never mutate state from detached tasks.
- Model replacement work with explicit task IDs or stored handles so `refresh` can cancel an older `onAppear` load.
- Convert cancellation into a deliberate state transition only when the user should see it; otherwise return to the previous stable state.


## Source references

- Redux, *Three Principles* — https://redux.js.org/understanding/thinking-in-redux/three-principles
- Model-View-Intent in iOS is a local state-machine pattern, not a single Apple-prescribed framework.
- Use this repo's `examples/mvi/` as the canonical convention for `State`, `Intent`, and Store ownership.

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://redux.js.org/understanding/thinking-in-redux/three-principles | Single source of truth and explicit actions justify the local Store/Intent/State loop. | `examples/mvi/` |

## Reference implementation notes

- `UserListState` should include users, loading, pagination, error, and optional route/event state.
- `UserListIntent` should name user meaning (`appeared`, `refreshed`, `selectedUser`) instead of UIKit/SwiftUI widget events.
- The Store should expose one public `dispatch(_:)`; helper reducers/effect methods can stay private to keep mutation centralized.

## Trade-offs

**Pros**: clear state transitions, framework-free, strong fit for mixed UIKit/SwiftUI teams.
**Cons**: easy to reinvent TCA poorly; large stores need reducer-style decomposition; one-shot events need discipline.

## Anti-patterns and fixes

- **View mutates state directly** -> make state `private(set)` and expose `dispatch`.
- **Intent mirrors control names** -> rename to product events, e.g. `saveTapped` becomes `saveRequested`.
- **Effects update state from arbitrary tasks** -> funnel results back through one main-actor dispatch path.

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
