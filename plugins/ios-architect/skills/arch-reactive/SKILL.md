---
name: arch-reactive
description: Reactive iOS architecture with Combine or RxSwift. Use for search, live feeds, replacement requests, debounced input, and stream-heavy SwiftUI or UIKit features.
---

# Reactive

Use Reactive when the feature is mostly about event streams: input changes,
request replacement, live updates, throttling, retry, or fan-out.

This is usually paired with another structural pattern:

- MVVM + Combine in SwiftUI or UIKit
- MVP/VIPER + RxSwift in UIKit
- Clean Architecture with reactive adapters at Presentation

## When To Use

- Search/typeahead with debounce and `switchToLatest`.
- WebSocket or push-driven lists.
- Form validation across several changing inputs.
- Replacement requests where only the newest response should render.

Avoid it when async/await is enough; streams have real cognitive cost.

## Structure

```
Features/Search/
  SearchViewModel.swift       // inputs, pipeline, outputs
  SearchView.swift            // binds UI to inputs and renders outputs
Domain/SearchService.swift
```

For a simple SwiftUI + Combine baseline, see `examples/mvvm-swiftui-combine/`.

## Rules

- Pipelines live in a ViewModel, Presenter, or Interactor, not in the view.
- `@Published` exposes state; subjects represent one-shot events or inputs.
- Use `debounce`, `removeDuplicates`, and `switchToLatest` intentionally.
- Recover errors at stream boundaries and expose user-safe state.
- Tie cancellables to the owning lifecycle.

## Failure Modes

- Nested subscriptions instead of composed operators.
- Missing cancellation, so an old request wins over a new one.
- UI-bound state published off the main actor.
- A view builds business pipelines directly.
- Multiple subscribers accidentally duplicate network calls.

## Review Checklist

- Is the operator choice tied to the behavior: debounce, throttle, merge, latest?
- Are old in-flight requests cancelled or ignored when required?
- Are errors converted to state instead of terminating the screen?
- Are cancellables retained and released with the screen?
- Does the view only bind inputs and render outputs?

## Migration Hand-Off

- To MVVM-SwiftUI Observation: replace `ObservableObject` with `@Observable` when streams are no longer needed.
- To MVI/TCA: turn input events into intents/actions and pipelines into effects.
- To Clean Architecture: move business rules below the stream layer into use cases.
