---
name: migrator
description: Migrate an iOS codebase from one architecture pattern to another. Covers all 12×12 source→target pairs across MVC, MVP, MVVM-UIKit, MVVM-SwiftUI, MVVM-C, VIPER, Clean Swift, Clean Architecture, TCA, Redux/ReSwift, RIBs, and Modular/TMA. Produces a phased plan with shared primitives, per-pair playbook, and rollback triggers. Use when the user wants to migrate, port, or replace the architecture of an existing iOS project.
---

# Migrator — Any-to-Any Architecture Migration

## Purpose

Move an iOS codebase from a **source** pattern to a **target** pattern with minimal disruption. Output is a phased migration plan rooted in a small set of reusable primitives, plus a per-pair playbook with the exact mechanical steps.

## Prerequisites

- Run `analyser` first to confirm the source pattern.
- Confirm the target pattern is right (run `researcher` if unsure).
- Confirm CI is green and there is a test baseline. If coverage is sparse, the first phase becomes "add characterisation tests on critical flows".

## Universal migration rules

1. **Never migrate the whole app in one go.** Strangler-fig per feature. Old and new patterns coexist behind a feature-folder boundary.
2. **Start with a leaf feature.** Pick a screen with few inbound dependencies. Avoid the home screen, authentication, and anything in the payment path on day 1.
3. **Tests come first.** If the source feature has no tests, write characterisation tests (snapshot + integration) before refactoring.
4. **Ship per phase.** Each phase merges to main and ships. No long-running branches.
5. **Keep public APIs stable.** When migrating a feature module, its `Interface` target's public symbols stay the same so callers don't change.
6. **Roll back triggers**: CI red for > 24h, crash rate up ≥ 10%, perf regression > 5%, dev velocity drop > 30%.

## Shared primitives

These are the building blocks every migration uses. The per-pair playbook is just a recipe over them.

### P1 — Extract domain model
Move plain `struct` model types out of view-controller files into a `Domain` folder/module. No UIKit/SwiftUI imports allowed.

### P2 — Introduce repository protocol
For each model with persistence/network access, define a `protocol XRepository` and inject it. Concrete impl lives in `Data/`. Old code can keep using a singleton; new code receives it via init.

### P3 — Extract ViewModel
Lift presentation state out of a `UIViewController` into a `final class XViewModel` (Combine) or `@Observable final class XModel` (SwiftUI). No UIKit/SwiftUI imports in the VM.

### P4 — Introduce Coordinator
Replace inline `navigationController.pushViewController` / `present` calls with calls on a `Coordinator` injected into the VC/VM. Coordinator owns the `UINavigationController`.

### P5 — Replace Coordinator with NavigationStack
For SwiftUI targets, switch to `NavigationStack(path:)` with a typed `enum Route` and `navigationDestination(for:)`. Keep a thin `Router` if deep-linking is needed.

### P6 — Wrap UIKit screen in UIHostingController
For UIKit-host migration to SwiftUI, write the new SwiftUI view and host it via `UIHostingController`. Old VC's parent Coordinator continues to push it.

### P7 — Wrap SwiftUI screen in UIViewControllerRepresentable
Reverse direction when SwiftUI host needs to embed legacy UIKit screens.

### P8 — Introduce Use Cases (Domain layer)
For each repository operation, define a `protocol XUseCase` with a single `execute(...)` method. ViewModels depend on use-cases, not repositories. Makes pre-conditions and business rules explicit.

### P9 — Convert ViewModel to Reducer (TCA)
Map VM properties → `State`, VM methods → `Action` cases, side-effects → `Effect`. Tests carry over by replacing async expectations with `TestStore` assertions.

### P10 — Split feature into Tuist/SPM module
Create `Interface`, `Sources`, `Tests`, optionally `Example`. Move feature into `Sources`, expose its public entry via `Interface`. App target depends on `Interface` only.

### P11 — Introduce dependency container
Single root composition (no service locator). For UIKit, instantiate in `SceneDelegate`. For SwiftUI, build in `@main App` `init`. For TCA, use `@DependencyClient`.

### P12 — Delete Massive View Controller
After P3, P4, P10, the original VC should have only `viewDidLoad`/`viewWillAppear` + glue. Delete inline business logic, target-actions for non-UI work, and any data-source code that belongs in a VM.

## Per-pair migration matrix

Rows = source, columns = target. Cell = ordered primitives + notes. `→` means "then". When the cell is `(identity)` no migration is required.

| From \ To | MVC | MVP | MVVM-UIKit | MVVM-SwiftUI | MVVM-C | VIPER | Clean Swift | Clean Arch | TCA | Redux/ReSwift | RIBs | Modular/TMA |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **MVC** | (identity) | P1→P3 (rename VM→Presenter, push via protocol) | P1→P2→P3 (Combine/Rx bindings) | P1→P2→P3 (`@Observable`, host via P6) | P1→P2→P3→P4 | P1→P3 then split V/I/P/E/R per screen; introduce Builder | P1→P3 then split V/I/P + Request/Response/ViewModel structs; add Worker | P1→P2→P3→P8→P11 | P1→P2→P3→P9→P11; consider strangler-fig per feature | P1→P2→P3, replace VM methods with Action enum + central Store; add subscribers in VCs | Only if team is Uber-scale: P1→P2→P3 then map V/VM/Coordinator → V/I/Router; pull in Rx | P10 first, then any of the above per-feature |
| **MVP** | Rare; collapse Presenter back into VC (downgrade) | (identity) | P3 (rename Presenter→ViewModel, add observable bindings) | P3 (`@Observable`) + P6 if hosting in UIKit | P3→P4 | Split Presenter into Interactor (rules) + Presenter (formatting), add Router, Builder, Entities | Split Presenter→Interactor+Presenter+Worker; add Request/Response/ViewModel models | P8 (Use Cases over current Presenter call sites) + P2 + P11 | P9 over Presenter | Same as MVC→Redux row | Same as MVC→RIBs row | P10 |
| **MVVM-UIKit** | Downgrade — don't | (semantic identity, just rename) | (identity) | Replace `@Published`+`ObservableObject` with `@Observable`; switch View layer to SwiftUI via P6 incrementally | P4 | P3 already done — split VM into Interactor (rules) + Presenter (formatting); add Router/Builder/Entities | Split VM into Interactor + Presenter; add Worker; introduce Request/Response/ViewModel structs | P8+P2+P11 | P9 | Convert VM mutations to Actions, introduce Store, subscribers replace bindings | Map VM → Interactor, Coordinator → Router, add Buildable; introduce Rx | P10 |
| **MVVM-SwiftUI** | Downgrade — don't | Reverse of MVP→MVVM-SwiftUI; rare | Replace `@Observable` with `ObservableObject`+`@Published`, swap View for UIKit-based binding | (identity) | P4 (Coordinator) — but consider P5 (NavigationStack + Router) instead | Awkward — VIPER and SwiftUI fight. Recommend stopping at Clean Architecture instead | Awkward in SwiftUI — recommend stopping at Clean Architecture | P8+P2+P11 | P9 (smooth in SwiftUI, especially with TCA macros) | Convert VM mutations to Actions; subscribe via `@StateObject` wrapper over Store; consider TCA instead | Not recommended; if forced: rebuild in UIKit + Rx first | P10 |
| **MVVM-C** | Downgrade | Rare | Strip Coordinator | Replace Coordinator with NavigationStack+Router (P5) | (identity) | Split VM into Interactor+Presenter, Coordinator becomes Router, add Builder+Entities | Same with Worker added and Request/Response/ViewModel structs | P8+P2+P11 (keep Coordinator inside Presentation layer) | P9 + replace Coordinator with TCA `Path` reducer | Convert VM mutations → Actions; Coordinator listens to Store for nav state | Map Coordinator→Router, VM→Interactor, add Buildable | P10 |
| **VIPER** | Downgrade | Collapse I+P into Presenter | Collapse I+P into VM; Router→Coordinator | Same + swap V layer for SwiftUI via P6 incrementally | Collapse I+P into VM, keep Router as Coordinator | (identity) | Reorganise — keep V/I/P, replace Router with cycle-based flow, add Worker and Request/Response/ViewModel | I→Use Cases; P→VM in Presentation; Router→Coordinator | P9 over VM-equivalent; Router→TCA Path | Collapse to a Store; Router subscribes to state | Map V→V, I→I, Router→Router, add Buildable; pull in Rx | P10 |
| **Clean Swift (VIP)** | Downgrade | Collapse Interactor into Presenter | Collapse Interactor+Presenter into VM; remove Request/Response/ViewModel structs | Same + SwiftUI swap | + Coordinator | Add Entities and Builder, rename Worker→Use Case-ish | (identity) | Promote Worker→Use Case; Interactor's rules → Domain layer; P→Presentation VM | P9 over Interactor+Presenter | Same as VIPER→Redux | Same as VIPER→RIBs | P10 |
| **Clean Architecture** | Downgrade | Collapse Presentation VM into Presenter | Add Combine bindings on Presentation VM | Add SwiftUI `@Observable` on Presentation VM | + Coordinator at Presentation | Split Presentation VM into Interactor+Presenter per screen, add Router/Entities/Builder | Same with Worker and Request/Response/ViewModel | (identity) | P9 over Presentation VMs; keep Domain and Data untouched | Convert VMs → Reducers (already pure-ish) → Store | Same as VIPER→RIBs | P10 (often already done) |
| **TCA** | Downgrade — don't | Rare | Reverse of MVVM-UIKit→TCA — flatten Reducer→VM | Reverse — flatten Reducer→`@Observable` model | Add Coordinator separate from TCA store (`Path`) | Awkward — split Reducer into Interactor (Effects) + Presenter (state→view-state) + Router | Same + Worker shape | Keep TCA as Presentation; pull out Use Cases (P8) for non-trivial business rules | (identity) | Strip Effects, replace Reducer with subscribing Store; usually a downgrade | Not recommended | P10 (TCA composes with modules naturally) |
| **Redux/ReSwift** | Downgrade | Rare | Replace global Store subscriptions with local VMs | Same in SwiftUI | + Coordinator | Reshape per-screen subscriptions into V/I/P; centralise routing in Router | Same with Worker | Keep Store as Presentation glue; pull out Use Cases | Reducer→Reducer is mostly mechanical; gain `@Reducer`+macros, `Effect`, TestStore | (identity) | Not recommended | P10 |
| **RIBs** | Strong downgrade | Rare | Map RIB(I)→VM, RIB(R)→Coordinator; drop Rx for Combine | Same + SwiftUI swap | (Interactor→VM, Router→Coordinator) | (Interactor→Interactor, Router→Router); drop Builder/Component | Add Worker, Request/Response/ViewModel | Pull out Domain layer per Interactor; Router→Coordinator | P9 per RIB; Rx→async/await | RIB tree → flat Store; lose hierarchy | (identity) | P10 (RIBs are already modular — flatten into Tuist modules) |
| **Modular/TMA** | Per-module downgrade | Per-module | Per-module migration to the row pattern | Per-module | Per-module | Per-module | Per-module | Per-module | Per-module | Per-module | Per-module | (identity / re-shard) |

## Phase template (use for every migration)

```
## Migration Plan: <Source> → <Target>

### Phase 0 — Baseline (1–2 days)
- [ ] Confirm source pattern with analyser
- [ ] CI green on main
- [ ] Add characterisation tests on <feature picked for first migration>
- [ ] Document chosen target conventions in CLAUDE.md/AGENTS.md

### Phase 1 — Pilot feature (1–2 weeks)
- [ ] Pick leaf feature: <name>
- [ ] Apply primitives: <ordered list from matrix cell>
- [ ] Ship behind feature flag if user-visible behaviour changes
- [ ] Retrospective: confirm the recipe before scaling

### Phase 2 — Roll out (per feature, parallel where possible)
- [ ] Feature A: apply recipe
- [ ] Feature B: apply recipe
- ...

### Phase 3 — Cleanup
- [ ] Delete dead code from old pattern
- [ ] Update docs, CLAUDE.md/AGENTS.md, onboarding
- [ ] Re-run analyser to confirm new state

### Rollback triggers
- CI red > 24h
- Crash rate +10%
- Perf regression > 5%
- Dev velocity drop > 30%
```

## Common cross-cutting concerns during any migration

- **Dependency injection**: introduce a root container (P11) before scaling the new pattern across features.
- **Navigation**: pick one of `Coordinator`, `NavigationStack+Router`, or `TCA Path` and apply it consistently across all migrated features.
- **Test infra**: provide a `FakeUserRepository` (or equivalent) in a shared test-support module; do not re-implement per feature.
- **Concurrency**: standardise on `async`/`await` + `@MainActor` annotations during migration; do not mix Combine, Rx, and async loosely.
- **Module graph**: if migrating to Modular/TMA, define `Interface` targets up front and depend only on `Interface` from sibling modules to avoid cycles.

## Hand-off

Once the per-pair plan is produced, suggest the user invoke:
- `arch-<target>` for target conventions and corner cases.
- `arch-<source>` for any residual cleanup of remaining source-pattern code.
