# iOS Architecture Patterns — Advantages, Disadvantages & Comparison

*A senior architect's reference for choosing an iOS app architecture (UIKit & SwiftUI). Covers 12 patterns with side-by-side comparison tables and per-pattern analysis.*

---

## How to read this document

This is a **decision document**, not a tutorial. It assumes you already know what a view controller, a reducer, and a coordinator are. Each pattern gets a short verdict, a pros/cons list, a "when to use / when to reject" call, and notes on how it fits UIKit vs SwiftUI.

The ratings are **relative to each other**, not absolute. A "★★☆☆☆" for testability on MVC does not mean MVC is untestable — it means it is hard *compared to* VIPER or TCA. Ratings are a senior-engineer consensus synthesized from the sources listed at the end, plus a working reference bundle of all 12 patterns (compilable UIKit/SwiftUI examples that build and pass tests on Xcode).

**Rating scale:** ★☆☆☆☆ (poor / very high cost) → ★★★★★ (excellent / very low cost). For "cost" rows (boilerplate, learning curve), more stars = *less* cost / easier.

The single most important thing in this document: **there is no best architecture.** All mainstream patterns are within striking distance of each other; the right choice is a function of team size, app lifespan, SwiftUI-vs-UIKit, and how much correctness matters. The tables exist to make that trade-off explicit.

---

## The 12 patterns at a glance

| # | Pattern | One-line identity | Primary UI fit | Sweet spot |
|---|---------|-------------------|----------------|------------|
| 1 | **MVC** (Apple Cocoa) | View controller owns everything | UIKit | Prototypes, ≤20 screens |
| 2 | **MVP** | Passive view + Presenter holds logic | UIKit | UIKit apps wanting testable presentation |
| 3 | **MVVM (UIKit)** | ViewModel + bindings (Combine/closures) | UIKit | Mainstream UIKit production apps |
| 4 | **MVVM (SwiftUI)** | `@Observable` model + declarative view | SwiftUI | Mainstream SwiftUI production apps |
| 5 | **MVVM-C** | MVVM + Coordinator/Router owns navigation | UIKit & SwiftUI | Medium/large apps with deep-linking |
| 6 | **VIPER** | View-Interactor-Presenter-Entity-Router | UIKit | Large, long-lived UIKit apps, big teams |
| 7 | **Clean Swift (VIP)** | Cycle: View→Interactor→Presenter→View | UIKit | Teams wanting VIPER rigor, less routing ceremony |
| 8 | **Clean Architecture** | Layered: Domain / Data / Presentation + Use Cases | UIKit & SwiftUI | Domain-heavy apps, long lifespan |
| 9 | **TCA** | State/Action/Reducer/Store, unidirectional | SwiftUI | Correctness-critical SwiftUI, capable team |
| 10 | **Redux / ReSwift** | Single global store, pure reducers, middleware | UIKit & SwiftUI | Cross-platform shared logic, Redux background |
| 11 | **RIBs** (Uber) | Router-Interactor-Builder tree, Rx-driven | UIKit | Uber-scale (30+ engineers), nested state |
| 12 | **Modular / TMA** | Build-graph layer; each feature is a module | UIKit & SwiftUI | ≥5 devs or ≥30 screens (composes *with* the above) |

> **Note on #12:** Modular/TMA is *orthogonal* to the others. It is not a UI pattern — it is how you slice the codebase into Tuist/SPM modules. You pick MVVM **or** TCA **or** Clean *inside* each module, and layer Modular/TMA on top. It is included because at scale it dominates the build-time and team-autonomy conversation.

---

## Master comparison matrix

Higher stars = better outcome / lower cost.

| Category | MVC | MVP | MVVM-UIKit | MVVM-SwiftUI | MVVM-C | VIPER | Clean Swift | Clean Arch | TCA | Redux | RIBs | Modular |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Unit testability** | ★☆☆☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★☆ | ★★★★★ | ★★★★☆ |
| **Runtime stability / fewer bugs** | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★☆ |
| **Speed of development (greenfield)** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ | ★☆☆☆☆ | ★★★☆☆ |
| **Scalability (large codebase)** | ★☆☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★★☆ | ★★★☆☆ | ★★★★★ | ★★★★★ |
| **Low boilerplate** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★☆☆ | ★☆☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ | ★☆☆☆☆ | ★★★☆☆ |
| **Easy learning curve** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★☆☆☆☆ | ★★★☆☆ | ★☆☆☆☆ | ★★★☆☆ |
| **AI / LLM-agent friendliness** | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★★☆ | ★★★☆☆ | ★★★★★ |
| **SwiftUI fit** | ★☆☆☆☆ | ★★☆☆☆ | ★★☆☆☆ | ★★★★★ | ★★★★☆ | ★★☆☆☆ | ★★☆☆☆ | ★★★★☆ | ★★★★★ | ★★★★☆ | ★☆☆☆☆ | ★★★★★ |
| **UIKit fit** | ★★★★★ | ★★★★★ | ★★★★★ | ★☆☆☆☆ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★☆ | ★★☆☆☆ | ★★★★☆ | ★★★★★ | ★★★★★ |
| **Navigation handling** | ★★☆☆☆ | ★★☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★★★ | ★★★★☆ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★☆☆ | ★★★★★ | ★★★★☆ |
| **Team-scale parallelism** | ★☆☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★☆☆ | ★★★★★ | ★★★★★ |
| **Ecosystem / longevity risk** | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★☆☆ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★☆☆☆ | ★★★★☆ |

### Reading the matrix

- **MVC / MVVM-SwiftUI** win on speed and simplicity, lose on scale and testability (MVC especially).
- **VIPER / Clean Swift / Clean Architecture** win on testability and large-team structure, lose on boilerplate and dev speed.
- **TCA** has the best stability + testability + AI-friendliness, at the cost of the steepest learning curve and library lock-in.
- **RIBs / Modular** dominate team-scale parallelism; RIBs is justified only at Uber scale, Modular composes with everything.
- **Ecosystem risk:** TCA, Redux/ReSwift, RIBs carry third-party-dependency risk; Apple-native patterns (MVC/MVVM/Clean) do not.

---

## Decision quick-reference

| If you are… | Use | Avoid |
|---|---|---|
| Prototyping / hackathon / ≤20 screens | MVC, MVVM-SwiftUI | VIPER, TCA, RIBs |
| Solo dev, new SwiftUI app | MVVM-SwiftUI (or plain MV) | VIPER, RIBs |
| Small team, new SwiftUI app, correctness matters | TCA (if 1+ has shipped it), else MVVM-SwiftUI + Coordinator | RIBs |
| Mainstream UIKit production app | MVVM-UIKit or MVVM-C | RIBs, Redux |
| Deep-linking / complex flows | MVVM-C | MVC, MVP |
| Large UIKit app, big team, long lifespan | VIPER or Clean Architecture | MVC |
| Domain/business-rule-heavy app | Clean Architecture | MVC, MVP |
| Cross-platform shared logic (Android Redux/KMP) | Redux / ReSwift | VIPER |
| 5+ devs OR 30+ screens | **Modular/TMA** + (MVVM/TCA/Clean inside) | monolithic anything |
| Uber-scale (30+ iOS engineers, nested state) | RIBs | — |
| LLM-agent-heavy workflow | TCA or Modular/TMA | MVC (Massive VC defeats agents) |

---

## Per-pattern analysis

### 1. MVC (Apple Cocoa)

**Verdict:** The default Apple pattern. Fastest to start, impossible to scale. Fine for prototypes; a liability for anything that lives.

The view controller *is* the unit under test, with no layer between it and the data. Networking, state, snapshot rendering, and navigation all accrete in the VC — the infamous "Massive View Controller."

**Pros**

- Zero ceremony; framework-native; fastest greenfield path.
- Every iOS dev already knows it; onboarding is instant.
- No third-party dependency, no longevity risk.

**Cons**

- Massive View Controller bloat is effectively inevitable past a few screens.
- Weak unit testability — testing requires forcing `view` loads and polling async UI.
- No layering: business logic, presentation, and navigation are entangled.

**When to use:** prototypes, throwaway apps, solo dev ≤20 screens, Apple-sample parity.
**When to reject:** any production app expected to grow.
**UI fit:** UIKit only. In SwiftUI the equivalent "everything in the View" anti-pattern is what the MV-vs-MVVM debate is about.

---

### 2. MVP (Model-View-Presenter)

**Verdict:** MVC's testable cousin. The view goes passive; a Presenter holds presentation logic behind a protocol. A solid, low-drama choice for UIKit teams that want testability without VIPER's ceremony.

**Pros**

- Presenter is plain Swift, fully unit-testable behind a `View` protocol (mock the view).
- Clear separation of presentation logic from the view controller.
- Modest learning curve; a natural step up from MVC.

**Cons**

- View protocol boilerplate per screen.
- Presenter can still become a dumping ground if business rules aren't pushed into a domain layer.
- No prescribed navigation story — pair with a Coordinator.

**When to use:** UIKit apps that want testable presentation without full Clean/VIPER.
**When to reject:** SwiftUI greenfield (use MVVM-SwiftUI); trivial screens.
**UI fit:** UIKit. The `@MainActor` Presenter protocol pattern keeps concurrency clean.

---

### 3. MVVM (UIKit)

**Verdict:** The mainstream UIKit production default. ViewModel exposes outputs the view binds to (Combine, closures, or RxSwift). Best balance of testability and familiarity for UIKit.

**Pros**

- ViewModel is highly testable in isolation.
- Bindings remove imperative UI-update code.
- Huge community, well-understood, no lock-in.

**Cons**

- Binding mechanism is a choice (Combine vs closures vs Rx) — inconsistency risk across a team.
- ViewModels bloat if they absorb networking + navigation + business rules.
- No built-in navigation — needs a Coordinator (→ MVVM-C).

**When to use:** the safe default for UIKit production apps.
**When to reject:** SwiftUI (use the SwiftUI variant); domain-heavy apps that need explicit Use Cases.
**UI fit:** UIKit. Combine bindings are idiomatic post-iOS 13.

---

### 4. MVVM (SwiftUI)

**Verdict:** The mainstream SwiftUI default — though contested. With the `@Observable` macro (iOS 17+), the ViewModel becomes a lightweight observable model and SwiftUI handles invalidation precisely. Note the active community debate: many argue SwiftUI's `@State`/`@Observable` already *is* the view model, and a separate VM layer (the "MV pattern") is often unnecessary.

**Pros**

- `@Observable` gives precise, automatic invalidation and good performance by default.
- Declarative views + observable model is clean and concise.
- Testable model; minimal binding boilerplate.

**Cons**

- The MVVM-vs-MV debate is real: a VM layer can be redundant for simple screens.
- iOS 17+ for `@Observable` (older code uses `ObservableObject`/Combine, more boilerplate).
- Still needs a navigation strategy for non-trivial flows (→ MVVM-C).

**When to use:** mainstream SwiftUI apps; add a VM only where a screen has real logic.
**When to reject:** UIKit; cases where plain `@State` in the view suffices (don't cargo-cult a VM).
**UI fit:** SwiftUI-native. This is the pattern SwiftUI was designed around.

---

### 5. MVVM-C (MVVM + Coordinator)

**Verdict:** MVVM with navigation extracted into a Coordinator (UIKit) or a typed Router driving `NavigationStack` (SwiftUI). The answer to "where does navigation live?" Excellent for deep-linking and reusable flows.

**Pros**

- Decouples navigation from views/VMs; deep-linking becomes straightforward.
- Coordinators/Routers are reusable across flows and testable.
- Clear navigation ownership — solves MVVM's biggest gap.

**Cons**

- Coordinator retain-cycle traps (forget `weak self` in closures).
- Extra layer to reason about.
- SwiftUI `NavigationStack` only pops from the tail; mid-stack removal needs a full path reset.

**When to use:** medium/large apps with deep-linking, A/B-routed flows, or reusable flows.
**When to reject:** tiny apps where navigation is trivial.
**UI fit:** Both. UIKit uses a Coordinator owning a `UINavigationController`; SwiftUI uses an `@Observable` Router holding a `[Route]` path.

---

### 6. VIPER

**Verdict:** Maximum separation of concerns. View, Interactor (business), Presenter (formatting), Entity, Router. The lowest coupling of any mainstream iOS pattern — and the highest boilerplate. Earns its keep only on large, long-lived UIKit codebases with big teams.

**Pros**

- Strictest separation → best test boundaries and modularity in large systems.
- Each component has one job; easy to reason about in isolation.
- Scales to big teams working in parallel.

**Cons**

- Heavy boilerplate (~5 files per screen) — punishing for small apps/prototypes.
- Over-engineering risk; steep onboarding.
- Weak SwiftUI story (designed for UIKit).

**When to use:** large, long-lived UIKit apps; big teams that value strict boundaries.
**When to reject:** small apps, rapid prototyping, SwiftUI greenfield.
**UI fit:** UIKit. `@MainActor` on Presenter/View/Router protocols keeps Swift-6 concurrency clean.

---

### 7. Clean Swift (VIP)

**Verdict:** VIPER's sibling with a unidirectional cycle (View → Interactor → Presenter → View) per scene. Keeps the rigor and testability, trades some of VIPER's routing ceremony for a tighter cycle.

**Pros**

- Excellent testability; each leg of the VIP cycle tests independently.
- Predictable unidirectional flow within a scene.
- Strong structure for medium/large UIKit apps.

**Cons**

- Still significant boilerplate (Models/Interactor/Presenter per scene).
- Smaller community than MVVM/VIPER; fewer learning resources.
- Scene-centric; cross-scene routing still needs a Router/Worker convention.

**When to use:** teams wanting VIPER-grade testability with a cleaner per-scene cycle.
**When to reject:** small apps; SwiftUI greenfield.
**UI fit:** UIKit.

---

### 8. Clean Architecture (layered)

**Verdict:** Not a UI pattern but a layering discipline — Domain (entities + Use Cases), Data (repositories), Presentation (MVVM/VIP/TCA). Makes the core business logic independent of frameworks, UI, and data sources. The strongest choice for domain-heavy, long-lived apps.

**Pros**

- Business rules independent of UI/DB/framework — swap any outer layer without touching the core.
- Use Cases are trivially testable; Domain is pure Swift.
- Ages well; resilient to platform/UI churn.

**Cons**

- Upfront layering cost; over-engineering risk for simple apps.
- Indirection (Use Cases, mappers, DTOs) adds files.
- Requires team discipline to keep the dependency rule (dependencies point inward).

**When to use:** domain/business-rule-heavy apps; long lifespan; multiple data sources.
**When to reject:** CRUD-thin apps; prototypes.
**UI fit:** Both — the Presentation layer can be UIKit-MVVM or SwiftUI-`@Observable`.

---

### 9. TCA (The Composable Architecture)

**Verdict:** Point-Free's SwiftUI-first framework. State / Action / Reducer / Store with unidirectional flow and exhaustive testing via `TestStore`. Best-in-class testability and stability for correctness-critical SwiftUI — if the team can absorb the curve and the lock-in.

**Pros**

- Exhaustive, deterministic testing (`TestStore` fails on any unasserted state change or effect).
- Composable: `Scope`, `ifLet`, `forEach`, `Stack` build big features from small reducers.
- `@Dependency` makes DI trivial; fewer production bugs in complex workflows.
- Strong fit for LLM agents: predictable, declarative, single mutation site.

**Cons**

- Steepest learning curve; requires functional-programming comfort and prior SwiftUI fluency.
- Boilerplate per feature; enum/state explosion without discipline.
- Performance footguns if `@ObservableState` is skipped (whole-state diffing).
- Library lock-in + ecosystem/longevity risk on a third party.

**When to use:** correctness-critical greenfield SwiftUI (payments, multi-step flows) with ≥1 engineer who has shipped TCA.
**When to reject:** trivial screens; teams new to Swift/SwiftUI; risk-averse on dependencies.
**UI fit:** SwiftUI-first (iOS 17 macros cut historical boilerplate). UIKit possible but unidiomatic.

---

### 10. Redux / ReSwift

**Verdict:** Single global store, pure reducers, side effects in middleware. Predictable and replayable; strongest when sharing logic/semantics across platforms. For greenfield SwiftUI, TCA generally supersedes it.

**Pros**

- One source of truth; replayable, time-travel-debuggable.
- Reducers are pure `(State, Action) -> State` — the easiest tests around.
- Portable across platforms (shared semantics with Android Redux / KMP).

**Cons**

- Async/middleware story weaker than TCA's `Effect`.
- iOS ecosystem is comparatively stagnant; longevity risk.
- Boilerplate per feature; global-store discipline required (selectors, `Equatable` projections).

**When to use:** cross-platform shared business logic; teams with Redux background.
**When to reject:** greenfield SwiftUI (prefer TCA); small apps.
**UI fit:** Both; pairs with SwiftUI or UIKit, but consider TCA first on SwiftUI.

---

### 11. RIBs (Uber)

**Verdict:** A hierarchical Router-Interactor-Builder tree, RxSwift-driven, with Builder/Component DI. Proven at hundreds-of-engineers scale. Highest boilerplate of any pattern; justified *only* at Uber scale with deeply nested persistent state. Reject by default.

**Pros**

- Proven to scale to hundreds of engineers and hundreds of RIBs.
- Strong isolation: routing, business, view, creation each have a distinct class — easy to test in isolation.
- Codegen + leak-detection + static-analysis tooling boosts large-team productivity.
- Cross-platform parity with Android RIBs.

**Cons**

- Highest boilerplate (~6 files per RIB); steep onboarding; tiny community.
- Hard RxSwift dependency.
- Poor SwiftUI story — designed for UIKit; SwiftUI needs custom bridging.
- Not distributed via SPM; significant longevity/ecosystem risk.

**When to use:** iOS team ≥30 engineers, deeply nested state, Android-parity requirement.
**When to reject:** essentially everyone else — the cost is not justified below Uber scale.
**UI fit:** UIKit.

---

### 12. Modular / TMA (The Modular Architecture)

**Verdict:** The build-graph layer, not a UI pattern. Each feature is a Tuist or SPM module with `Interface` / `Sources` / `Tests` / `Example` targets; you pick MVVM/TCA/Clean *inside* each module. At scale it is the single biggest lever on build time and team autonomy.

**Pros**

- Fastest incremental builds — only changed modules recompile.
- Per-feature `Example` apps let features build/run in isolation.
- Strict dependency boundaries enforced by the module graph (App depends on `Interface` only).
- Best LLM-agent fit: small files, predictable layout, opaque internals.

**Cons**

- Setup cost (Tuist or hand-rolled SPM workspace).
- Upfront module-graph design — easy to over- or under-shard.
- Public-API discipline must be enforced via `Interface` targets.
- Pure-SPM at very large scale can hit slow transitive dependency resolution (teams move to Tuist/Bazel).

**When to use:** ≥5 engineers or ≥30 screens; multi-team verticals; agent-heavy workflows.
**When to reject:** small apps (a 5-screen app modularized is premature).
**UI fit:** Both — it composes with any in-module pattern.

---

## UIKit vs SwiftUI — the cross-cutting decision

The architecture choice is increasingly downstream of the UI-framework choice:

- **UIKit projects** gravitate to MVC → MVP → MVVM-UIKit → MVVM-C → VIPER/Clean Swift as they scale. RIBs sits at the far end.
- **SwiftUI projects** gravitate to MVVM-SwiftUI (or plain MV) → MVVM-C → TCA / Clean Architecture as correctness needs rise.
- **Patterns that bridge both:** MVVM-C, Clean Architecture, Redux, and Modular/TMA work in either world.
- **The `@Observable` shift (iOS 17+)** materially changed SwiftUI architecture: precise invalidation, less Combine plumbing, and a live debate about whether a separate ViewModel layer is still warranted. The honest answer: add a ViewModel where a screen has real logic; skip it where `@State` suffices.

## On "AI-friendliness"

LLM coding agents do best with architectures that have **small files, predictable boundaries, explicit data flow, and a single state-mutation site.** That ranks **TCA** and **Modular/TMA** highest (declarative, composable, opaque module internals), with Clean Swift/Clean Architecture close behind (rigid structure agents can follow). VIPER is rigid too, but its five-files-per-screen sprawl strains an agent's context window, so it rates lower. **MVC ranks lowest** — a Massive View Controller is exactly the kind of sprawling, implicit-state file agents struggle to edit safely. This is a genuine and increasingly relevant selection axis, not a gimmick.

---

## Bottom line

1. **Default SwiftUI:** MVVM-SwiftUI (`@Observable`), add Coordinator when navigation grows, reach for TCA only when correctness justifies the curve.
2. **Default UIKit:** MVVM-UIKit / MVVM-C; escalate to VIPER or Clean Architecture for large, long-lived, domain-heavy systems.
3. **At scale (5+ devs / 30+ screens):** layer Modular/TMA over whichever in-module pattern you chose. This matters more than the in-module pattern itself.
4. **RIBs and Redux/ReSwift** are niche: RIBs for Uber-scale parity, Redux for cross-platform shared logic. Most teams should skip both.
5. **There is no universal winner.** Match the pattern to team size, app lifespan, UI framework, and how much correctness costs you when it's wrong.

---

## Sources

Synthesized from a working reference bundle of all 12 patterns (compilable UIKit/SwiftUI examples that build and pass tests on Xcode), plus the following:

- Max, *The Ultimate Guide to Modern iOS Architecture in 2025* — https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f
- Chandra Welim, *iOS Architecture in 2026: Which One Should You Actually Use?* — https://medium.com/@chandra.welim/ios-architecture-in-2026-which-one-should-you-actually-use-793917181411
- Rashad Shirizada, *MVVM vs VIPER vs TCA* — https://medium.com/@rashadsh/mvvm-vs-viper-vs-tca-best-architecture-for-your-next-app-159e11e333e9
- Ravi, *MVVM vs MVP vs Clean Swift vs VIPER (2025)* — https://ravi6997.medium.com/comparing-app-architecture-mvvm-vs-mvp-vs-clean-swift-vs-viper-on-modern-projects-d587546325f5
- 7Span, *Modern iOS App Architecture in 2026: MVVM vs Clean Architecture vs TCA* — https://7span.com/blog/mvvm-vs-clean-architecture-vs-tca
- Dignizant, *iOS Architecture Patterns: Select the Right One* — https://dignizant.com/posts/ios-architecture-patterns-select-the-right-one-for-your-app
- swiftyplace, *TCA: How Architectural Design Decisions Influence Performance* (Karin Prater) — https://www.swiftyplace.com/blog/the-composable-architecture-performance
- HackerNoon, *The Composable Architecture: Strengths, Trade-Offs, and Performance Tips* — https://hackernoon.com/the-composable-architecture-strengths-trade-offs-and-performance-tips
- Point-Free, *Composable Architecture FAQ* — https://www.pointfree.co/blog/posts/141-composable-architecture-frequently-asked-questions
- Matteo Manferdini, *The Myth of the MV pattern* — https://matteomanferdini.com/swiftui-mv-pattern/
- Matteo Manferdini, *MVVM in SwiftUI for a Better Architecture* — https://matteomanferdini.com/swiftui-mvvm/
- Alexey Naumov, *Clean Architecture for SwiftUI* — https://nalexn.github.io/clean-architecture-swiftui/
- Apple Developer Forums, *Stop using MVVM for SwiftUI* — https://developer.apple.com/forums/thread/699003
- flyingharley.dev, *MVVM in SwiftUI: From ObservableObject to @Observable* — https://flyingharley.dev/posts/mvvm-architecture-in-swift-ui-from-observable-object-to-observable
- Tuist, *The Modular Architecture (TMA)* — https://docs.tuist.io/guide/scale/tma-architecture
- Andre Nogueira, *iOS Modularization Tools* — https://andrevini.dev/blog/ios-modularization-tools
- Qonto, *Choosing the right tool to modularize our iOS codebase* — https://medium.com/qonto-way/choosing-the-right-tool-to-modularize-our-ios-codebase-869a8ef568b8
- uber/RIBs — https://github.com/uber/RIBs
- Uber, *Designing the New Driver App Architecture (RIBs)* — https://www.uber.com/us/en/blog/driver-app-ribs-architecture/
- pointfreeco/swift-composable-architecture — https://github.com/pointfreeco/swift-composable-architecture
- ReSwift/ReSwift — https://github.com/ReSwift/ReSwift

*Ratings are a senior-engineer synthesis and are inherently judgment calls; treat them as a starting point for your own context, not as benchmarks.*


