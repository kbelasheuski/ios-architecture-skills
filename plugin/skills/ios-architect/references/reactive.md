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

## Decision examples

- Use this when the core problem is stream behavior: debounce, latest-wins, fan-out, retry, or live updates.
- Reject it when async/await models the flow clearly; streams add cognitive cost.
- First safe slice: put the pipeline in a ViewModel and keep Subjects private inputs.

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


## Testing strategy

- Inject schedulers/clocks and test pipelines with virtual time; do not rely on wall-clock sleeps.
- Drive pipelines from fake upstream publishers or fake repositories so dependency timing is controlled.
- Assert operator semantics directly: debounce suppresses noise, `switchToLatest` cancels old work, retry stops at the intended boundary.
- Assert user-visible state transitions for loading, success, empty, and stale-result replacement.
- Test error recovery so one failed upstream does not terminate the screen forever.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert the pipeline emits loading and content states for the first upstream page. | Fake publisher plus test scheduler |
| Latest-wins search | Assert a newer query cancels or supersedes stale upstream results. | Test scheduler and switchToLatest seam |
| Repository failure | Assert stream failure becomes an error state instead of terminating UI bindings. | Fake publisher failure branch |
| Detail save | Assert save pipeline emits saving then updated detail state. | FakeUserRepository updateCalls |

## Concurrency and cancellation

- Use `switchToLatest`, `flatMap(maxPublishers:)`, or explicit cancellation depending on whether latest-wins, fan-out, or sequential work is required.
- Publish UI state on the main actor/main scheduler and keep upstream work on background queues only where needed.
- Tie cancellables to feature lifetime and use `share`/`multicast` when multiple subscribers should not duplicate side effects.


## Source references

- Apple Combine documentation — https://developer.apple.com/documentation/combine
- ReactiveX operators — https://reactivex.io/documentation/operators.html

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://developer.apple.com/documentation/combine | Combine pipelines are used only where stream replacement, cancellation, and scheduling are first-class behavior. | `examples/mvvm-swiftui-combine/` |

## Reference implementation notes

- A search feature should expose input subjects or methods (`queryChanged`, `retry`) and output immutable state.
- Use a single pipeline for request replacement: query -> debounce -> remove duplicates -> service publisher -> latest result.
- Keep the repository/service protocol below the pipeline so domain behavior can move to async/await later.

## Operator choice

| Behavior | Prefer |
|---|---|
| Latest request wins | `map` to publisher + `switchToLatest` |
| Ignore repeated same input | `removeDuplicates` |
| Wait for typing to settle | `debounce` |
| Limit rapid taps but keep first/last semantics clear | `throttle` |
| Share one side effect across observers | `share` or explicit state store |

## Trade-offs

**Pros**: precise event composition, strong cancellation semantics, excellent for noisy inputs and live updates.
**Cons**: operator misuse is subtle; debugging is harder than async/await; tests need scheduler control.

## Anti-patterns and fixes

- **Nested `sink` calls** -> compose operators and keep one terminal subscription per output.
- **Subject used as mutable state** -> expose read-only state and keep subjects private inputs.
- **Every subscriber starts a network call** -> share upstream work or move the side effect behind a repository.

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
