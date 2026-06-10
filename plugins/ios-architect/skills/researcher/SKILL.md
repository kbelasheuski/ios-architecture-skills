---
name: researcher
description: Greenfield iOS architecture decision. Asks structured discovery questions about the project, team, timeline, tech stack, and constraints, then recommends a primary architecture with rationale and a fallback. Use when the user is starting a new app, picking a stack, or asking "what should we use".
---

# Researcher — Architecture Selection for a New iOS Project

## Purpose

Given a fresh project, decide which architecture pattern (and which modularisation strategy) to adopt. The output is a written recommendation: primary choice, fallback, and concrete first-week setup actions.

## When to use

- "We're starting a new iOS app — what should we use?"
- "Should we go MVVM or TCA?"
- Pre-kickoff planning, RFC drafting, architecture-review meeting prep.

## Discovery — ask in this order

Work through these to ground the recommendation. You don't need every answer before
saying anything useful — once team size, primary UI framework, deployment target, and
product shape are known, you can give a provisional recommendation and refine as more
detail arrives. Prioritise the questions whose answers would actually change the choice;
skip the rest if the user has already converged. Flag any recommendation made on partial
information as provisional.

### 1. Product shape

- App category (consumer, enterprise, regulated/fintech, on-device-heavy, content-heavy)?
- Expected screen count at launch and at 12 months (rough)?
- Critical UX flows that span many screens (onboarding, checkout, multi-step forms)?
- Offline-first or online-first?
- Real-time / push-driven UI?
- Deep-linking requirements?

### 2. Team

- Number of iOS engineers today; in 6 months; in 18 months?
- Seniority mix (junior:mid:senior)?
- Prior experience with: VIPER, TCA, RxSwift, Combine, SwiftUI?
- Cross-platform with Android, KMM, or React Native expected?

### 3. Tech stack

- Deployment target (iOS 15, 16, 17+)?
- UIKit, SwiftUI, or mixed? If mixed — which is the primary going forward?
- Existing internal frameworks (logging, networking, design system) that lock decisions?
- Dependency tooling (SPM, CocoaPods, Carthage, Tuist, XcodeGen)?
- CI build-time budget per PR?

### 4. Constraints

- Hard deadline (MVP date)?
- Compliance / audit needs (HIPAA, PCI, banking, healthcare)?
- Testability target (line coverage %, integration suite expected)?
- Performance constraints (startup, scroll perf, memory ceiling)?
- LLM-agent / vibecoding heaviness in workflow?

### 5. Future plans

- Plan to share business logic across platforms?
- Plan to extract reusable modules into separate SDK / framework?
- Plan to onboard external contractors / agencies who will own features?

## Decision heuristics

These are strong defaults, not laws. Walk them top-to-bottom and take the first
that fits, but treat the result as a starting recommendation — the real drivers are
the project's build graph, code-ownership boundaries, release cadence, CI time budget,
and domain boundaries. If those point elsewhere, say so and explain the trade-off.

1. **Solo developer, MVP, ≤ 20 screens, throwaway risk** → MVVM-SwiftUI (`@Observable`), single Xcode project, no modularisation. Plain MVC only if every screen is trivial and there are no networking-driven flows.
2. **UIKit-locked legacy migration target** → MVVM-C as in-module pattern, introduce UIHostingController bridge, plan gradual SwiftUI migration.
3. **Regulated domain (banking, healthcare, fintech) with audit-trail requirements** → Clean Architecture (layered) + MVVM at Presentation, optional VIPER per critical screen. Modularise early.
4. **Team ≥ 5 OR ≥ 30 screens at launch** → modularisation (Modular/TMA) becomes a strong default; the win is build-graph and ownership isolation, so weigh it against actual module boundaries and CI cost rather than screen count alone. Choose the in-module pattern from the rest of the list.
5. **Greenfield SwiftUI + correctness-critical (payments, scheduling, multi-step flows with side effects)** → TCA + Modular, *if* the team has or will invest in the learning curve. Otherwise MVVM-SwiftUI + Clean layering.
6. **Greenfield SwiftUI, medium product, mixed-seniority team** → MVVM-SwiftUI + Clean Architecture layering inside each feature module.
7. **Cross-platform business logic shared with Android, no KMM** → Redux/ReSwift (logic portable as plain Swift), or push toward KMM and keep MVVM on the iOS side.
8. **Uber-scale: ≥ 30 iOS engineers AND deeply nested, persistent state hierarchy** → RIBs. Below that scale, the cost rarely pays off.
9. **Default fallback** → MVVM-SwiftUI (`@Observable`) + SPM workspace, Clean layering inside each feature.

## Output format

When you have all answers, produce:

```
## Recommendation

Primary: <pattern> + <modularisation strategy>
Fallback: <pattern> + <modularisation strategy>

Rationale: <2–5 sentences tying answers back to the rule that fired>

Trade-offs accepted:
- <bullet>
- <bullet>

First-week setup:
1. <action> (e.g. create SPM workspace with Core, Domain, DesignSystem modules)
2. <action> (e.g. scaffold UserList feature using arch-<pattern> skill's reference impl)
3. <action> (e.g. wire CI to run xcodebuild + xcodebuild test on App target)
4. <action> (e.g. add CLAUDE.md / AGENTS.md to repo root with chosen conventions)

Suggested next skill: arch-<pattern>
```

## Anti-patterns to flag

- Picking VIPER for a 3-person team.
- Picking TCA without a senior engineer who has shipped TCA before.
- Picking RIBs for anything below Uber scale.
- Skipping modularisation on a ≥ 30-screen app — recoverable but costly.
- Locking deployment target to iOS 15 "just in case" — costs the team `@Observable`'s ergonomics.
- Picking MVC for any production app.

## Hand-off

After delivering the recommendation, suggest the user run the `arch-<pattern>` skill to scaffold the first feature, and (if migration from any existing code is in play) point to `migrator`.
