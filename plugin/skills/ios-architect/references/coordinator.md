# Coordinator

Coordinator is a navigation layer, not a full app architecture. Pair it with
MVVM, MVP, Clean Architecture, TCA, or another presentation pattern.

## When To Use

- View controllers or views currently push/present directly.
- Deep links need one owner.
- The same screen appears in several flows.
- Navigation tests matter.
- UIKit and SwiftUI flows need to coexist during migration.

## Decision examples

- Use this when navigation is repeated, deep-linked, or split between UIKit and SwiftUI.
- Reject it as a standalone architecture; pair it with MVVM, MVP, Clean, TCA, or another feature pattern.
- First safe slice: move one push/present path into a Coordinator and leave state ownership unchanged.

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


## Testing strategy

- Unit test route parsing and route-to-screen decisions without UIKit when possible.
- Cover rejected routes and deep-link failure paths so invalid input does not mutate navigation state.
- In UIKit, test coordinator behavior with fake navigation controllers or spies for push/present/pop.
- In SwiftUI, test the route path as value state and keep a tiny integration test for `NavigationStack` wiring.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert screen state loads through the model while navigation stays in the route owner. | FakeUserRepository plus route store |
| Deep link | Assert a user detail URL becomes the expected typed route path. | Route parser unit test |
| Back navigation | Assert popping the path releases the child route state. | Route store assertion |
| Detail save | Assert save updates data without mutating unrelated route state. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- Treat navigation mutations as main-actor work.
- Parse deep links and load route prerequisites outside views, then hop to the main actor to mutate navigation.
- Coordinators should cancel flow-scoped tasks and release child coordinators when a flow finishes.


## Source references

- Apple `NavigationStack` — https://developer.apple.com/documentation/swiftui/navigationstack
- Apple UIKit navigation controllers — https://developer.apple.com/documentation/uikit/uinavigationcontroller

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://developer.apple.com/documentation/swiftui/navigationstack | Typed route state is the source of truth for SwiftUI navigation and deep-link replay. | `examples/coordinator/` |

## Reference implementation notes

- SwiftUI references should model routes as `Hashable` values and bind them to `NavigationStack(path:)`.
- UIKit references should keep a parent coordinator alive for the flow and release child coordinators on completion.
- Deep links should parse into the same typed route model used by in-app navigation.

## Trade-offs

**Pros**: navigation becomes testable, reusable, and easier to migrate between UIKit and SwiftUI.
**Cons**: coordinators can become service locators; too many tiny coordinators add ceremony; SwiftUI path ownership must stay clear.

## Anti-patterns and fixes

- **Coordinator constructs repositories directly** -> inject feature factories or module interfaces.
- **ViewModel owns a concrete coordinator** -> expose route intents/callbacks and let the parent translate them.
- **Deep links push views directly** -> parse to typed routes first, then render the route.

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
