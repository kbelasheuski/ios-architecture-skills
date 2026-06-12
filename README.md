<h1 align="center">🏗️ iOS Architecture Skills</h1>

<p align="center">
  <a href="https://github.com/kbelasheuski/ios-architecture-skills/actions/workflows/examples.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/kbelasheuski/ios-architecture-skills/examples.yml?branch=main&style=for-the-badge"></a>
  <a href="https://github.com/kbelasheuski/ios-architecture-skills/actions/workflows/swiftlint.yml"><img alt="SwiftLint" src="https://img.shields.io/github/actions/workflow/status/kbelasheuski/ios-architecture-skills/swiftlint.yml?branch=main&label=SwiftLint&style=for-the-badge"></a>
  <img alt="Version 0.1.1" src="https://img.shields.io/badge/Version-0.1.1-555?style=for-the-badge">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge"></a>
</p>

iOS Architect is a plugin-ready architecture skill with reference playbooks for choosing, auditing, refactoring,
and migrating iOS app architectures. It covers MVC, MVP, MVVM (Combine and
`@Observable`), MVVM-C, MVI, Reactive Combine/Rx, Coordinator, VIPER, Clean
Swift, Clean Architecture, TCA, Redux/ReSwift, RIBs, and modular SPM/Tuist setups.

The bundle is intentionally lean: the installable plugin package lives in `plugin/`, the router skill lives at
`plugin/skills/ios-architect/SKILL.md`, and detailed playbooks live under
`plugin/skills/ios-architect/references/`. The repo keeps only marketplace manifests plus the skill package;
runtime-specific custom-agent examples are intentionally not included.

## What You Get

| Part | What it does |
|---|---|
| `references/researcher.md` | Chooses an architecture for a new app through structured discovery questions. |
| `references/analyser.md` | Audits an existing codebase, scores it on practical architecture axes, and recommends refactor or migration. |
| `references/migrator.md` | Provides an any-to-any migration playbook built on reusable migration primitives. |
| `references/selection-guide.md` | Provides quick routing when the pattern is unclear or the requested pattern looks mismatched. |
| `references/<pattern>.md` | One per pattern: when to use it, folder layout, trade-offs, corner cases, anti-patterns, and a worked example. |

The agent should route to the most specific reference for the task and only pull in
heavier reference material when the implementation details matter. Shared routing notes live in `plugin/skills/ios-architect/references/`.

## Architectures

| # | Pattern | Identity | UI fit | Sweet spot |
|---|---------|----------|--------|------------|
| 1 | **MVC** | View controller owns everything | UIKit | Prototypes, small UIKit apps |
| 2 | **MVP** | Passive view + Presenter owns presentation logic | UIKit | UIKit apps that need testable presentation |
| 3 | **MVVM-UIKit** | ViewModel + bindings | UIKit | Mainstream UIKit production |
| 4 | **MVVM-SwiftUI** | `@Observable` or Combine model + declarative view | SwiftUI | Mainstream SwiftUI production |
| 5 | **MVVM-C** | MVVM + Coordinator/Router owns navigation | UIKit and SwiftUI | Medium/large apps, deep-linking |
| 6 | **MVI** | State + Intent + dispatch, unidirectional | UIKit and SwiftUI | Deterministic feature state without TCA |
| 7 | **Reactive** | Combine/Rx input streams -> state | UIKit and SwiftUI | Search, live feeds, replacement requests |
| 8 | **Coordinator** | Navigation layer with typed routes/flows | UIKit and SwiftUI | Deep links and reusable flows |
| 9 | **VIPER** | View-Interactor-Presenter-Entity-Router | UIKit | Large, long-lived UIKit codebases |
| 10 | **Clean Swift** | VIP cycle: View -> Interactor -> Presenter -> View | UIKit | VIPER-like boundaries with less routing ceremony |
| 11 | **Clean Architecture** | Layered Domain/Data/Presentation + Use Cases | UIKit and SwiftUI | Domain-heavy apps with long lifespan |
| 12 | **TCA** | State/Action/Reducer/Store, unidirectional | SwiftUI | Correctness-critical SwiftUI |
| 13 | **Redux/ReSwift** | Single global store, pure reducers, middleware | UIKit and SwiftUI | Cross-platform shared logic |
| 14 | **RIBs** | Router-Interactor-Builder tree | UIKit | Uber-scale teams and deeply nested state |
| 15 | **Modular TMA** | Build-graph layer; each feature is a module | UIKit and SwiftUI | Larger teams or codebases; composes with the above |

Full per-pattern analysis is in
[iOS-Architecture-Comparison.md](iOS-Architecture-Comparison.md), with a score
grid in [iOS-Architecture-Comparison.xlsx](iOS-Architecture-Comparison.xlsx).

## Enable

This repo is packaged as a marketplace for Claude Code and Codex:

| Runtime | Manifest | Contents |
|---|---|---|
| Codex | `.agents/plugins/marketplace.json` | `plugin/.codex-plugin/plugin.json` plus the router skill and references |
| Claude | `.claude-plugin/marketplace.json` | `plugin/.claude-plugin/plugin.json` plus the router skill and references |

For Claude Code:

```bash
claude plugin marketplace add kbelasheuski/ios-architecture-skills
claude plugin install ios-architect@ios-architecture-skills
```

For Codex:

```bash
codex plugin marketplace add kbelasheuski/ios-architecture-skills
codex plugin add ios-architect@ios-architecture-skills
```

After install, both runtimes expose the `ios-architect` router skill and its references through the plugin package.

## Usage

Common prompts and the reference they should route to:

| Prompt | Reference |
|---|---|
| "Recommend an architecture for a new app" | `references/researcher.md` |
| "Audit this codebase and tell me what architecture we have" | `references/analyser.md` |
| "Make a plan to migrate from VIPER to TCA" | `references/migrator.md` |
| "Show me the TCA folder structure for a new feature" | `references/tca.md` |
| "What are the corner cases for MVVM-C in SwiftUI?" | `references/mvvm-c.md` |
| "Model this feature as State + Intent without TCA" | `references/mvi.md` |
| "This search screen needs debounce and latest request wins" | `references/reactive.md` |
| "Extract navigation and deep links out of these screens" | `references/coordinator.md` |
| "We are not sure which architecture fits" | `references/selection-guide.md` |

## License

[MIT](LICENSE)
