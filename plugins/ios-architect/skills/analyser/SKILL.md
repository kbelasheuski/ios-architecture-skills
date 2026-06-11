---
name: analyser
description: Audit an existing iOS codebase, detect the current architecture (or closest match), score it across nine parameters, and produce either a refactor plan to improve it in place OR a migration recommendation. Use when the user asks for a codebase audit, refactor planning, "what architecture do we have", or wants to know if it's worth migrating.
---

# Analyser — Existing-Codebase Architecture Audit

## Purpose

Reverse-engineer the architecture from source, identify pain points, score the codebase, and produce one of:
1. An **in-place refactor plan** (when the current pattern is salvageable).
2. A **migration recommendation** that hands off to the `migrator` skill.

## Inputs

- Repository root path.
- Optional: deployment target, team size, business constraints (ask if missing).

## Step 1 — Inventory

Run these checks with `Grep`/`Glob`/`Bash`. Cache results before reasoning.

These greps are **coarse signals, not proof**. Names like `Interactor`, `Presenter`,
`Builder`, `Coordinator`, `Store`, `Reducer` are reused across patterns (and across
unrelated domain code), so a raw match count classifies poorly on a mature or mixed
repo. Treat each signal as a hypothesis to confirm by opening representative files and
reading how the pieces actually wire together — directory layout, who-owns-navigation,
how state flows. Never report a pattern from grep counts alone.

| Signal | Command | What it tells you |
|---|---|---|
| File count by suffix | `find . -name "*.swift" \| wc -l`, group by directory | Codebase size |
| ViewController count | `grep -r "UIViewController" --include="*.swift" \| wc -l` | UIKit dominance |
| SwiftUI View count | `grep -r ": View {" --include="*.swift" \| wc -l` | SwiftUI dominance |
| Coordinator presence | `grep -r "Coordinator" --include="*.swift" \| wc -l` | MVVM-C / VIPER router |
| VIPER markers | `grep -rE "Interactor\|Presenter\|Builder" --include="*.swift"` | VIPER / Clean Swift |
| Clean Swift markers | `grep -rE "Worker\|Models\.swift" --include="*.swift"` | VIP layout |
| TCA markers | `grep -rE "@Reducer\|Effect<\|@ObservableState" --include="*.swift"` | TCA |
| RIBs markers | `grep -rE "Routing\|Buildable\|Interactor:" --include="*.swift"` | RIBs |
| ReSwift markers | `grep -rE "ReSwift\|StoreSubscriber\|@MainActor.*Action" --include="*.swift"` | Redux |
| MVI markers | `grep -rE "Intent\|dispatch\\(\|struct State" --include="*.swift"` | MVI |
| Reactive markers | `grep -rE "AnyPublisher\|PassthroughSubject\|switchToLatest\|DisposeBag" --include="*.swift"` | Reactive Combine/Rx |
| Observation usage | `grep -rE "@Observable\|@ObservableState" --include="*.swift"` | iOS 17 modernity |
| Combine usage | `grep -r "@Published" --include="*.swift" \| wc -l` | ObservableObject MVVM |
| Modularity | `find . -name "Package.swift"`, `find . -name "Project.swift"` | SPM / Tuist modules |
| ViewController bloat | `awk 'END{print NR}'` on top-10 largest VCs | Massive View Controller signal |
| Test coverage | `find . -name "*Tests.swift"` count vs source | Test maturity |

## Step 2 — Classify

Map signals to a primary architecture using the table below, then **assign a
confidence level** and state it in the output:

- **high** — directory layout, naming, and wiring all agree on one pattern, confirmed by reading representative files.
- **medium** — signals mostly agree but with notable exceptions, or the repo mixes patterns.
- **low** — signals conflict, the repo is transitional, or grep counts disagree with what the code actually does.

Do **not** resolve a close call by file-count majority alone — open the files and let
the wiring decide. When confidence is medium or low, say so explicitly and ask the
engineer to confirm before any recommendation depends on the classification.

| Dominant signals | Primary architecture |
|---|---|
| Many `UIViewController` subclasses, few `ViewModel` files | MVC (likely with MVC bloat) |
| `ViewModel` files + `Presenter` protocols, no Coordinator | MVP or MVVM (check binding mechanism) |
| `ViewModel` + `@Published`, navigation in VCs | MVVM (UIKit) |
| `ViewModel` + `@Observable` or `ObservableObject` in SwiftUI Views | MVVM (SwiftUI) |
| MVVM signals + `Coordinator` files | MVVM-C |
| `Interactor` + `Presenter` + `Router` + `Entity` + `Builder` per screen | VIPER |
| `Interactor` + `Presenter` + `Worker` + `Models.swift` (Request/Response/ViewModel) | Clean Swift (VIP) |
| `@Reducer`, `Effect`, `Store` | TCA |
| Feature `State` + `Intent` + `dispatch` without TCA dependency | MVI |
| `Store`, `Reducer`, `Action` enum, but no `@Reducer` macro | Redux/ReSwift |
| `AnyPublisher`/Rx streams, debounce/throttle/latest pipelines | Reactive layer (note alongside primary pattern) |
| `Buildable`, `Routing`, `Component`, Rx-heavy | RIBs |
| Folder `Domain/` + `Data/` + `Presentation/` with repository protocols | Clean Architecture (layered) |
| Multiple SPM packages or Tuist modules — orthogonal axis | Modular / TMA (note alongside primary) |

Call out **mixed** codebases explicitly: "MVVM-C with VIPER pockets in payments module".

## Step 3 — Score

Score the current state 1–5 on each of: Testability, Readability, Performance, Modularity, Onboarding, Navigation, State-mgmt discipline, Build-time, LLM-agent friendliness. Use these heuristics:

- **Testability**: ratio of test files to source files, presence of mock/fake infra.
- **Readability**: avg `UIViewController` LoC; file count per feature folder.
- **Performance**: `@Observable` usage (good), unbounded `@Published` chains feeding huge VMs (bad), excessive `WithViewStore` w/o `@ObservableState` (TCA legacy).
- **Modularity**: number of SPM/Tuist modules vs feature count.
- **Onboarding**: README presence, CLAUDE.md/AGENTS.md presence, contributing guide.
- **Navigation**: explicit Coordinator/NavigationStack discipline vs ad-hoc segues/`present`.
- **State mgmt**: pure-function reducers vs mutable singletons.
- **Build-time**: time `xcodebuild` cleanly; if not available, count `import` graph density.
- **Agent friendliness**: file sizes (small = good), naming conventions (predictable = good), cross-file action chains (bad).

## Step 4 — Decide: refactor in place or migrate?

**Refactor in place** when:
- Primary architecture matches team skills + product size from the `researcher` decision table.
- Pain points are local (a few massive view controllers, one tangled feature).
- Migration cost exceeds refactor cost by ≥ 3× engineer-weeks.

**Migrate** when:
- Primary architecture clearly mismatched (e.g. VIPER in a 3-dev SwiftUI shop).
- Pattern's pain compounds with growth (e.g. ObservableObject churn on 80+ screens).
- Modernisation unlocks ≥ 2 of: testability, perf, agent friendliness.

## Step 5 — Output

### If refactor in place

```
## Audit Result

Detected: <pattern> (confidence: high/medium/low)
Mixed pockets: <list or "none">
Modularisation: <none / SPM workspace / Tuist>

Scorecard (1–5):
- Testability: x — <evidence>
- Readability: x — <evidence>
- Performance: x — <evidence>
- Modularity: x — <evidence>
- Onboarding: x — <evidence>
- Navigation: x — <evidence>
- State mgmt: x — <evidence>
- Build time: x — <evidence>
- Agent friendliness: x — <evidence>

## Top pain points (ranked)
1. <pain> — <file:line evidence> — <severity>
2. ...

## In-place refactor plan
Phase 1 (this sprint, 1–3 days each):
- <task>
Phase 2 (this quarter):
- <task>
Phase 3 (next quarter):
- <task>

Suggested next skill: arch-<pattern>  (for conventions / corner cases)
```

### If migration recommended

```
## Audit Result
... (same as above)

## Migration recommendation
From: <current pattern>
To:   <target pattern>
Reason: <2–3 sentences>

Expected cost: <engineer-weeks>
Expected payback: <metric>

Hand off to: migrator  (with from=<current>, to=<target>)
```

## Anti-patterns to flag during audit

- Single `AppState` singleton mutated from VCs.
- VMs that import UIKit/SwiftUI.
- Coordinator instances retained by VCs (cycle risk).
- `WithViewStore` everywhere in TCA 1.7+ codebase (legacy, should be `@ObservableState`).
- `NavigationStack` paths held in 5 different `@State` properties across one feature.
- VIPER modules where Presenter calls Interactor synchronously and blocks main thread.
- Repository protocols in same module as their concrete impl (defeats Clean's dependency-inversion).

## Hand-off

After producing the audit, point to:
- `arch-<pattern>` skill — for in-place refactor conventions.
- `migrator` skill — for cross-pattern migration playbook.

## Failure modes

- Grep counts are treated as proof.
- Mixed architecture pockets are hidden to make the answer cleaner.
- Missing tests are ignored when recommending migration.
- File-size and wiring evidence is not cited.
- The recommendation changes architecture when a local refactor would solve the pain.

## Review checklist

- Were representative files opened after coarse search?
- Is the detected pattern reported with confidence?
- Are mixed pockets and modularisation called out separately?
- Does every major finding cite concrete evidence?
- Is the output clearly refactor-in-place or migrate, not both at once?
