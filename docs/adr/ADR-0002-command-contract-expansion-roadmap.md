# ADR-0002: Command Contract Expansion Roadmap

- Status: Accepted
- Date: 2026-02-19

## Context

Current CLI contract does not yet support host overlays, scoped sync-all operations, promote workflow, or strict verification mode.

## Decision

Roadmap includes adding:

1. `ossetup install --host <id|auto>`
2. `ossetup sync-all --scope config|state|all`
3. `ossetup promote ...`
4. `ossetup verify --strict`

with contract tests for each positive/negative option path.

## Consequences

Positive:

- Better support for config-complete migration.
- Reduced manual steps when switching devices.
- Stronger guarantees around reproducibility and validation.

Costs:

- CLI surface area grows and requires stronger docs/test maintenance.
- Backward compatibility adapters needed during transition.
