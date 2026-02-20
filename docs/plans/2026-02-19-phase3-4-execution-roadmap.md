# Phase 3-4 Execution Roadmap

## Status Update (2026-02-20)

1. Phase 3A implemented:
   - layered manifests (`core/targets/hosts`) and deterministic resolver shipped.
   - compatibility adapter from legacy targets shipped for transition window.
2. Phase 3B implemented:
   - `install --host`, `sync-all --scope`, `promote`, `verify --strict` shipped with contract tests.
3. Phase 3C/3D updated:
   - architecture/runbook/docs refreshed.
   - CI and tests expanded for new contracts.
4. Phase 4 hard cutover:
   - adapter and legacy manifest path removed in `v1.0.0`.

## Scope

Execute remaining product phases after `v0.2.0` closeout:

1. Manifest layering foundation.
2. Command contract expansion.
3. Documentation completion pack.
4. CI/test hardening.
5. Migration safety and adapter removal.

## Phase 3A: Manifest Layering Foundation

Deliverables:

- `manifests/layers/core.yaml`
- `manifests/layers/targets/{linux-debian,macos}.yaml`
- `manifests/layers/hosts/<host-id>.yaml`
- merge resolver module
- compatibility adapter from current manifests to layered model

Acceptance:

- deterministic precedence test coverage
- existing install/sync flows continue to work during migration window

## Phase 3B: Command Contract Expansion

Deliverables:

- `install --host <id|auto>`
- `sync-all --scope config|state|all`
- `promote` command skeleton + core flow
- `verify --strict`

Acceptance:

- CLI help and option parsing tests updated
- positive and negative tests for each new option/command

## Phase 3C: Documentation Completion Pack

Deliverables:

- runbooks:
  - `docs/runbooks/DEBUGGING.md`
  - `docs/runbooks/RELEASE.md`
- ADRs:
  - `docs/adr/ADR-0001-manifest-layering-roadmap.md`
  - `docs/adr/ADR-0002-command-contract-expansion-roadmap.md`
- data contracts:
  - `docs/architecture/DATA-CONTRACTS.md`

Acceptance:

- docs-consistency checks include new canonical docs
- README index references new docs

## Phase 3D: CI/Test Hardening

Deliverables:

- extend CI/test suite for layering and new command contracts
- migration regression tests

Acceptance:

- matrix passes on Linux/macOS for all new command paths

## Phase 4: Rollout and Migration Safety

Deliverables:

- layered-only runtime contract
- removal of legacy manifest path (`manifests/targets/*.yaml`)
- staged removal checklist in cleanup inventory

Acceptance:

- no stale references except intentional history docs
- dead-reference tests pass before adapter removals
