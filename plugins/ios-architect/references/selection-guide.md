# Architecture Selection Guide

Use this when the user asks which architecture to choose, or when a requested
pattern looks mismatched.

## Quick Flow

1. Stream-heavy feature: search, live feed, WebSocket, debounce, replacement requests?
   Start with `arch-reactive`. Pair with MVVM, MVP, VIPER, or Clean as the structural layer.
2. Strict state machine with replayable state, but no third-party dependency?
   Use `arch-mvi`.
3. Strict unidirectional flow and TCA dependency is already accepted?
   Use `arch-tca`.
4. Main problem is navigation, deep links, or reusable flows?
   Use `arch-coordinator`. Pair it with MVVM, MVP, Clean, or TCA.
5. Domain rules and infrastructure swaps matter more than screen mechanics?
   Use `arch-clean-architecture`.
6. Large UIKit module with strict role separation?
   Use `arch-viper` or `arch-clean-swift`.
7. Primary scaling problem is team ownership or build graph?
   Use `arch-modular-tma`, then choose an in-module pattern.
8. Default for new SwiftUI iOS 17 apps:
   Use `arch-mvvm-swiftui`; add `arch-coordinator` or Clean layering when the app grows.

## Fit Signals

| Signal | Better fit |
|---|---|
| iOS 17 SwiftUI, normal screen state | `arch-mvvm-swiftui` |
| SwiftUI but project already uses `ObservableObject` / `@Published` | `arch-reactive` or `arch-mvvm-swiftui` with Combine variant |
| Noisy input streams and cancellation-heavy work | `arch-reactive` |
| Reducer-like state transitions without TCA | `arch-mvi` |
| Deep-linking and flow reuse | `arch-coordinator` |
| Business rules must be isolated from UI | `arch-clean-architecture` |
| Existing UIKit with presenters | `arch-mvp`, `arch-viper`, or `arch-clean-swift` |
| Global app state and reducer discipline | `arch-redux-reswift` or `arch-tca` |
| Uber-scale RIB tree already in place | `arch-ribs` |

## Good Combinations

- MVVM + Coordinator: screen state in models, navigation in coordinator.
- MVVM + Reactive: screen structure in MVVM, noisy effects in Combine/Rx pipelines.
- Clean Architecture + MVVM: domain/data isolation with simple presentation.
- Clean Architecture + TCA: domain/data stay plain, reducers handle presentation state.
- Modular/TMA + any pattern: module boundaries are orthogonal to in-module design.
- VIPER + Reactive: UIKit role split with stream-heavy interactors.

When combining patterns, name which layer each one owns. Do not let two patterns
own the same state or navigation boundary.
