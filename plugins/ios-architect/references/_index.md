# iOS Architecture Reference Index

Use this file as the quick map before loading a pattern skill.

## Pattern Map

| Need | Start here |
|---|---|
| Small UIKit app, legacy sample parity | `arch-mvc` |
| Passive UIKit view and testable presenter | `arch-mvp` |
| UIKit state binding with Combine | `arch-mvvm-uikit` |
| SwiftUI on iOS 17 with Observation | `arch-mvvm-swiftui` |
| SwiftUI with `ObservableObject` / Combine | `arch-reactive` or `arch-mvvm-swiftui` |
| Navigation ownership and deep links | `arch-coordinator` |
| MVVM plus navigation layer | `arch-mvvm-c` |
| Explicit state machine, no dependency on TCA | `arch-mvi` |
| Strict SwiftUI unidirectional flow with TestStore | `arch-tca` |
| Single global store | `arch-redux-reswift` |
| Layered domain/data/presentation | `arch-clean-architecture` |
| VIP request/response cycle | `arch-clean-swift` |
| Large UIKit module separation | `arch-viper` |
| RIB tree | `arch-ribs` |
| Build graph and team ownership | `arch-modular-tma` |

## Shared Contract

Each architecture should answer the same questions:

- when the pattern fits
- where state lives
- where side effects live
- how navigation is owned
- how dependencies are injected
- what tests prove the boundary
- what failure modes to watch
- what a reviewer should check

Use `selection-guide.md` when the user has not picked a pattern yet.
