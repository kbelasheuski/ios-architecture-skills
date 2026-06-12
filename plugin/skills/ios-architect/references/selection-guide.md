# Architecture Selection Guide

Use this when the user asks which architecture to choose, or when a requested
pattern looks mismatched.

## Quick Flow

1. Stream-heavy feature: search, live feed, WebSocket, debounce, replacement requests?
   Start with `reactive`. Pair with MVVM, MVP, VIPER, or Clean as the structural layer.
2. Strict state machine with replayable state, but no third-party dependency?
   Use `mvi`.
3. Strict unidirectional flow and TCA dependency is already accepted?
   Use `tca`.
4. Main problem is navigation, deep links, or reusable flows?
   Use `coordinator`. Pair it with MVVM, MVP, Clean, or TCA.
5. Domain rules and infrastructure swaps matter more than screen mechanics?
   Use `clean-architecture`.
6. Large UIKit module with strict role separation?
   Use `viper` or `clean-swift`.
7. Primary scaling problem is team ownership or build graph?
   Use `modular-tma`, then choose an in-module pattern.
8. Default for new SwiftUI iOS 17 apps:
   Use `mvvm-swiftui`; add `coordinator` or Clean layering when the app grows.

## Fit Signals

| Signal | Better fit |
|---|---|
| iOS 17 SwiftUI, normal screen state | `mvvm-swiftui` |
| SwiftUI but project already uses `ObservableObject` / `@Published` | `reactive` or `mvvm-swiftui` with Combine variant |
| Noisy input streams and cancellation-heavy work | `reactive` |
| Reducer-like state transitions without TCA | `mvi` |
| Deep-linking and flow reuse | `coordinator` |
| Business rules must be isolated from UI | `clean-architecture` |
| Existing UIKit with presenters | `mvp`, `viper`, or `clean-swift` |
| Global app state and reducer discipline | `redux-reswift` or `tca` |
| Uber-scale RIB tree already in place | `ribs` |


## Decision scorecard

Score each candidate from 1-5, then reject any pattern with a hard mismatch before comparing totals.

| Axis | Stronger signal |
|---|---|
| Team size and ownership | Modular/TMA, VIPER, Clean Architecture, RIBs when many people touch separate features. |
| UI stack | SwiftUI favors MVVM-SwiftUI, MVI, TCA; UIKit favors MVVM-UIKit, MVP, VIPER, Clean Swift. |
| Correctness risk | TCA/MVI/Clean Architecture when state transitions and effects must be exhaustively tested. |
| Stream complexity | Reactive when debounce, latest-wins, live updates, or fan-out dominate the feature. |
| Navigation complexity | Coordinator or MVVM-C when deep links, tabs, modals, and reusable flows matter. |
| Build graph pressure | Modular/TMA when compile time and ownership boundaries are the bottleneck. |
| Migration cost | Prefer the smallest pattern move that introduces the missing boundary first. |

## Reject conditions

- Do not choose MVC for a feature expected to own networking, editing, pagination, and navigation long-term.
- Do not choose TCA only for fashion if the team will not maintain reducer/effect tests.
- Do not choose VIPER/RIBs for tiny teams unless module isolation is already a real pain.
- Do not choose Reactive when async/await plus a simple model expresses the behavior clearly.

## Output template

```markdown
## Recommendation
Primary: <pattern>
Fallback: <pattern>

## Why
- <top fit signal>
- <main trade-off>

## First implementation slice
1. <smallest feature/boundary>
2. <tests to add>
3. <migration or build-graph guard>
```

## Good Combinations

- MVVM + Coordinator: screen state in models, navigation in coordinator.
- MVVM + Reactive: screen structure in MVVM, noisy effects in Combine/Rx pipelines.
- Clean Architecture + MVVM: domain/data isolation with simple presentation.
- Clean Architecture + TCA: domain/data stay plain, reducers handle presentation state.
- Modular/TMA + any pattern: module boundaries are orthogonal to in-module design.
- VIPER + Reactive: UIKit role split with stream-heavy interactors.

When combining patterns, name which layer each one owns. Do not let two patterns
own the same state or navigation boundary.
