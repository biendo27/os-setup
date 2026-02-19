# ADR-0001: Manifest Layering Roadmap

- Status: Proposed
- Date: 2026-02-19

## Context

Current manifest model is target/profile centric. Future phases require clearer separation between shared desired state, target-specific overlays, and host-specific overlays.

## Decision

Adopt layered manifests with precedence:

1. `core`
2. `target`
3. `host`

using deterministic merge rules and compatibility adapters for existing manifests.

## Consequences

Positive:

- Better portability across machines.
- Cleaner migration path for config-complete goals.
- Improved traceability for agent/human contributors.

Costs:

- Requires resolver implementation and migration tests.
- Temporary complexity during dual-format support window.
