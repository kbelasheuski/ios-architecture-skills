# iOS Architecture Reference Index

Use this file as the quick map before loading a pattern reference.

## Reference Map

| Need | Read |
|---|---|
| Small UIKit app, legacy sample parity | `mvc` |
| Passive UIKit view and testable presenter | `mvp` |
| UIKit state binding with Combine | `mvvm-uikit` |
| SwiftUI on iOS 17 with Observation | `mvvm-swiftui` |
| SwiftUI with `ObservableObject` / Combine | `reactive` or `mvvm-swiftui` |
| Navigation ownership and deep links | `coordinator` |
| MVVM plus navigation layer | `mvvm-c` |
| Explicit state machine, no dependency on TCA | `mvi` |
| Strict SwiftUI unidirectional flow with TestStore | `tca` |
| Single global store | `redux-reswift` |
| Layered domain/data/presentation | `clean-architecture` |
| VIP request/response cycle | `clean-swift` |
| Large UIKit module separation | `viper` |
| RIB tree | `ribs` |
| Build graph and team ownership | `modular-tma` |

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
