---
name: arch-modular-tma
description: Modular / TMA (The Modular Architecture) — each feature is a Tuist or SPM module with Interface, Sources, Tests, Example targets. Orthogonal to in-module pattern (MVVM, TCA, etc.). Use for medium-to-large teams (≥5 devs or ≥30 screens).
---

# Modular / TMA (The Modular Architecture)

**Source references:**
- Tuist, *The Modular Architecture* — https://docs.tuist.dev/en/guides/develop/projects/tma-architecture
- tuist/microfeatures-example — https://github.com/tuist/microfeatures-example
- ronanociosoig/Tuist-Pokedex — https://github.com/ronanociosoig/Tuist-Pokedex
- Apple, *Bundling Resources with a Swift Package* — https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package

This pattern is **orthogonal** to in-module pattern. Inside each module pick MVVM, Clean, TCA, etc.

## When to use

- Team ≥ 5 engineers, or codebase ≥ 30 screens.
- Builds slowing past 2 min per incremental change.
- Multiple teams owning distinct verticals.
- LLM-agent-heavy workflow (small files, predictable boundaries).

## Folder structure (Tuist)

```
Workspace.swift
Tuist/
  Config.swift
  ProjectDescriptionHelpers/
    Project+Templates.swift
Projects/
  App/
    Sources/UsersApp.swift
    Project.swift
  Core/
    Networking/
      Interface/Sources/NetworkingInterface.swift
      Sources/Networking.swift
      Tests/NetworkingTests/NetworkingTests.swift
      Project.swift
    DesignSystem/
      Sources/DSColors.swift
      Sources/DSButtons.swift
      Project.swift
  Domain/
    UserDomain/
      Sources/User.swift
      Sources/UserRepository.swift
      Sources/UseCases/FetchUsersUseCase.swift
      Sources/UseCases/FetchUserUseCase.swift
      Sources/UseCases/UpdateUserUseCase.swift
      Tests/UserDomainTests.swift
      Project.swift
  Data/
    UserData/
      Sources/LiveUserRepository.swift
      Sources/UserDTO.swift
      Tests/UserDataTests.swift
      Project.swift
  Features/
    UserListFeature/
      Interface/Sources/UserListFeatureInterface.swift
      Sources/UserListView.swift
      Sources/UserListModel.swift
      Tests/UserListFeatureTests.swift
      Example/Sources/UserListExampleApp.swift
      Project.swift
    UserDetailFeature/
      Interface/Sources/UserDetailFeatureInterface.swift
      Sources/UserDetailView.swift
      Sources/UserDetailModel.swift
      Tests/UserDetailFeatureTests.swift
      Example/Sources/UserDetailExampleApp.swift
      Project.swift
  TestSupport/
    UserDomainTestSupport/
      Sources/FakeUserRepository.swift
      Sources/Fixtures.swift
      Project.swift
```

Module dependency rule: **App depends on Features' `Interface` only**; `Sources` opaque. Features depend on `UserDomain` + `Core/Networking/Interface` + `Core/DesignSystem`. `UserData` depends on `UserDomain` + `Core/Networking/Interface`. `TestSupport` depends on `UserDomain` (it lives in Sources, not behind an Interface — test targets only).

## Reference implementation

The worked modular layout lives in **`examples/modular-tma/`** — `UserDomain` /
`UserData` modules, `UserListFeature` / `UserDetailFeature` each split into an
`Interface` target + opaque `Sources` + a per-feature `Example` app, plus the Tuist
`Project+Templates.swift` helper and the App composition root.

> **This is a build-graph layer, not a UI pattern** — it composes *with* MVVM / TCA /
> Clean inside each feature's `Sources`. The example uses MVVM-SwiftUI per feature.
> The Tuist variant requires **Tuist** installed; the SPM-only variant below needs no
> extra tooling. `examples/modular-tma/Package.swift` is a real multi-target SPM graph
> (`Domain`, `UserDomain`, `UserData`, and per-feature `Interface` + `Sources` targets):
> each feature's `Model`/`View` is internal to its `Sources` target, so the
> `Interface`/`Sources` boundary is enforced by the compiler, not just folders.

Key things to notice:

- **`Interface` vs `Sources` split is the whole point** — the App and sibling features import only `<Feature>Interface` (a thin public API), never the implementation, so changing `Sources` never recompiles dependents.
- **Each feature has its own `Example` app target** — features build and run in isolation without the full app, which is what keeps incremental builds and ownership clean.
- **`UserDomain` is pure Swift, dependency-free**; `UserData` implements its repository protocol; `TestSupport` exposes fakes to test targets only.
- **The App target is the composition root** — it's the only module that sees every feature's `Interface` and wires them together.

## SPM-only variant (no Tuist)

For teams that prefer pure SPM:

```
Package.swift                            (umbrella) OR
Packages/<Module>/Package.swift          (per-module, recommended at scale)
App/UsersApp.xcodeproj                   ties packages together
```

Each `Package.swift` declares two products per feature: `<Name>Interface` and `<Name>`. App target depends on `*Interface` only. Test support package exposes `FakeUserRepository`, `Fixtures`.

## Pros / cons

**Pros**
- Fastest incremental builds.
- Per-feature Example apps speed iteration without launching the full app.
- Strict dependency boundaries enforced by module graph.
- Best LLM-agent fit: small files, predictable layout, opaque internals.

**Cons**
- Setup cost (Tuist or hand-rolled SPM workspace).
- Upfront module-graph design — easy to over- or under-shard.
- Public-API discipline must be enforced (Interface targets).

## Corner cases

- **Interface targets**: expose only protocols, structs, entry-point factories. No implementations.
- **Resource bundles**: Tuist needs explicit `resources:` declaration; SPM uses `resources: [.process(...)]`.
- **Cross-feature navigation**: a feature depends only on another feature's `Interface`. App-level Router holds typed routes.
- **Previews inside `Sources`**: provide `previewValue` for dependencies so SwiftUI previews work without the App target.
- **Test mocks**: define `FakeUserRepository` in `UserDomainTestSupport` so multiple feature modules import it.
- **Tuist version pinning**: pin `.tuist-version` in repo to avoid drift across machines.
- **Module circular deps**: introduce a third module (`Shared` or a new `Interface`) to break cycles; never split Domain in two.
- **AnyView at the App level**: acceptable for cross-feature plumbing where types can't leak; use `some View` inside a single module.

## Anti-patterns

- Module importing another feature's `Sources` directly.
- Single "Common" module everything depends on (build bottleneck).
- Resources duplicated across modules instead of pulled from `DesignSystem`.
- Hand-editing the Xcode project — always regenerate via `tuist generate`.
- Modularising a 5-screen app — premature.
- `@_implementationOnly import` to hide a transitive dep (breaks ABI).

## Migration hand-off

- Combine with any in-module pattern: see `arch-mvvm-swiftui`, `arch-clean-architecture`, `arch-tca`, etc.
- From a monolith: P10 (split into modules) first, then per-feature pattern migrations from `migrator`.
- Tooling: `tuist generate`, `tuist focus <FeatureName>` to compile only one feature.

## Failure modes

- `Interface` target exposes implementation types.
- Feature modules import sibling `Sources` targets.
- One shared module becomes the new monolith.
- The app target reaches around factories and constructs feature internals.

## Review checklist

- Does the compiler enforce Interface/Sources boundaries?
- Does the app depend on feature interfaces only?
- Are public APIs small and stable?
- Are test-support fakes kept out of production targets?
- Is the module split justified by ownership, build time, or reuse?
