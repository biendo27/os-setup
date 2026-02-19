# Contributing

## Workflow

1. Create feature branch or worktree.
2. Implement changes in small, reviewable batches.
3. Keep cleanup actions tracked in `docs/cleanup/cleanup-inventory.md`.
4. Update docs when contracts or behavior change.

## Required Checks

Run all checks before opening or updating PR:

```bash
bats tests
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do bash -n "$f"; done
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/targets/*.yaml; do jq -e . "$f" >/dev/null; done
```

If available locally, also run:

```bash
shellcheck -S error $(rg -l '^#!/usr/bin/env bash' bin lib hooks popos-migration/scripts tests) bin/ossetup
```

## Cleanup Rules

1. Every candidate must be listed in `docs/cleanup/cleanup-inventory.md`.
2. Classify each item as:
   - `remove-now`
   - `archive-first`
   - `keep`
3. Do not remove compatibility-sensitive items without:
   - deprecation notice,
   - migration notes,
   - test coverage.

## Testing Standards

1. Add tests for new behavior and regressions.
2. Prefer contract-style tests for CLI entrypoints and shims.
3. Reject false-positive patterns in tests (e.g. direct `! grep` in bats assertions).

## Documentation Standards

1. Keep these docs in sync:
   - `README.md`
   - `docs/architecture/ARCHITECTURE.md`
   - `docs/architecture/INVARIANTS.md`
   - `docs/agents/AGENT_CONTEXT.md`
   - `docs/deprecations.md`
   - `docs/migration-notes.md`
