<h1 align="center">🏗️ iOS Architecture Skills</h1>

<p align="center">
  <a href="https://github.com/kbelasheuski/ios-architecture-skills/actions/workflows/validate-skills.yml"><img alt="Validate Skills" src="https://img.shields.io/github/actions/workflow/status/kbelasheuski/ios-architecture-skills/validate-skills.yml?branch=main&label=Skills&style=for-the-badge"></a>
  <a href="https://github.com/kbelasheuski/ios-architecture-skills/actions/workflows/examples.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/kbelasheuski/ios-architecture-skills/examples.yml?branch=main&style=for-the-badge"></a>
  <a href="https://github.com/kbelasheuski/ios-architecture-skills/actions/workflows/swiftlint.yml"><img alt="SwiftLint" src="https://img.shields.io/github/actions/workflow/status/kbelasheuski/ios-architecture-skills/swiftlint.yml?branch=main&label=SwiftLint&style=for-the-badge"></a>
  <a href="https://agentskills.io/home"><img alt="Agent Skills Compatible" src="https://img.shields.io/badge/Agent%20Skills-Compatible-purple?style=for-the-badge"></a>
  <img alt="Version 0.1.1" src="https://img.shields.io/badge/Version-0.1.1-555?style=for-the-badge">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge"></a>
</p>

iOS Architect is a plugin-ready skill bundle for choosing, auditing, refactoring,
and migrating iOS app architectures. It covers MVC, MVP, MVVM (Combine and
`@Observable`), MVVM-C, MVI, Reactive Combine/Rx, Coordinator, VIPER, Clean
Swift, Clean Architecture, TCA, Redux/ReSwift, RIBs, and modular SPM/Tuist setups.

The bundle is intentionally lean: the installable plugin lives in
`plugins/ios-architect/`, shared skills live under
`plugins/ios-architect/skills/`, Claude gets a tracked agent definition in
`plugins/ios-architect/agents/`, and Codex gets an optional custom-agent example
in `plugins/ios-architect/codex-agents/`.

## What You Get

| Skill | What it does |
|---|---|
| `researcher` | Chooses an architecture for a new app through structured discovery questions. |
| `analyser` | Audits an existing codebase, scores it on practical architecture axes, and recommends refactor or migration. |
| `migrator` | Provides an any-to-any migration playbook built on reusable migration primitives. |
| `arch-<pattern>` | One per pattern: when to use it, folder layout, trade-offs, corner cases, anti-patterns, and a worked example. |

The agent should route to the most specific skill for the task and only pull in
heavier reference material when the implementation details matter. Shared routing
notes live in `plugins/ios-architect/references/`.

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
| 15 | **Modular/TMA** | Build-graph layer; each feature is a module | UIKit and SwiftUI | Larger teams or codebases; composes with the above |

Full per-pattern analysis is in
[iOS-Architecture-Comparison.md](iOS-Architecture-Comparison.md), with a score
grid in [iOS-Architecture-Comparison.xlsx](iOS-Architecture-Comparison.xlsx).

## Enable

This repo is packaged as a marketplace for Claude Code and Codex:

| Runtime | Manifest | Contents |
|---|---|---|
| Codex | `.agents/plugins/marketplace.json` | `plugins/ios-architect/.codex-plugin/plugin.json` plus shared skills |
| Claude | `.claude-plugin/marketplace.json` | `plugins/ios-architect/.claude-plugin/plugin.json`, `plugins/ios-architect/agents/ios-architect.md`, and shared skills |

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

For Claude, use the `ios-architect` agent exposed by the plugin after install.

For Codex, the plugin exposes the shared skills. If you also want a named Codex
custom agent, copy the optional example:

```bash
mkdir -p .codex/agents
cp plugins/ios-architect/codex-agents/ios-architect.toml .codex/agents/ios-architect.toml
```

For a global Codex custom agent:

```bash
mkdir -p ~/.codex/agents
cp plugins/ios-architect/codex-agents/ios-architect.toml ~/.codex/agents/ios-architect.toml
```

The optional Codex agent intentionally leaves `model` unset so the runtime or
user configuration can choose the model. It only sets high reasoning effort and
architecture-specific instructions.

## Usage

Common prompts and the skill they should route to:

| Prompt | Skill |
|---|---|
| "Recommend an architecture for a new app" | `researcher` |
| "Audit this codebase and tell me what architecture we have" | `analyser` |
| "Make a plan to migrate from VIPER to TCA" | `migrator` |
| "Show me the TCA folder structure for a new feature" | `arch-tca` |
| "What are the corner cases for MVVM-C in SwiftUI?" | `arch-mvvm-c` |
| "Model this feature as State + Intent without TCA" | `arch-mvi` |
| "This search screen needs debounce and latest request wins" | `arch-reactive` |
| "Extract navigation and deep links out of these screens" | `arch-coordinator` |

## Examples

Fourteen examples are SwiftPM packages with XCTest coverage:

`mvc`, `mvp`, `mvvm-uikit`, `mvvm-swiftui`, `mvvm-swiftui-combine`,
`mvvm-c`, `mvi`, `coordinator`, `viper`, `clean-swift`,
`clean-architecture`, `tca`, `redux-reswift`, and `modular-tma`.

`ribs` remains reference-only because Uber's RIBs framework is not distributed
through Swift Package Manager.

Run an example on a Mac with Xcode:

```bash
cd examples/clean-swift
xcodebuild test -scheme CleanSwiftExample \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

TCA uses macros, so add `-skipMacroValidation`:

```bash
cd examples/tca
xcodebuild test -scheme TCAExample -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Deployment floor is iOS 17 for every buildable example.

The examples follow the shared spec in
[plugins/ios-architect/skills/REFERENCE_FEATURE.md](plugins/ios-architect/skills/REFERENCE_FEATURE.md) and vendor their own
domain, data, presentation, and test support so they can be inspected in
isolation.

## License

[MIT](LICENSE)
