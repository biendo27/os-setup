# Debugging Runbook

## Purpose

Provide a deterministic sequence for diagnosing install/sync/verify issues.

## Quick Triage

1. Confirm command and options used.
2. Capture environment:
   - target OS
   - shell
   - current branch/commit
3. Reproduce with explicit command.

## Baseline Health Checks

```bash
./bin/ossetup doctor
bats tests
```

If failures appear, collect output verbatim.

## Common Debug Paths

## Manifest Issues

```bash
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/layers/core.yaml manifests/layers/targets/*.yaml; do
  jq -e . "$f" >/dev/null || echo "invalid: $f"
done
```

## Script Syntax and Lint

```bash
for f in $(rg --files -g '*.sh' bin lib hooks popos-migration/scripts tests) bin/ossetup; do
  bash -n "$f"
done

shellcheck -S error $(rg -l '^#!/usr/bin/env bash' bin lib hooks popos-migration/scripts tests) bin/ossetup
```

## Sync Mismatch

1. Run preview first:
   - `./bin/ossetup sync --preview`
2. Compare mapped files from `manifests/dotfiles.yaml`.
3. Validate optional vs required entries.

## Verify Failures

1. Run:
   - `./bin/ossetup verify --report`
   - `./bin/ossetup verify --strict --report`
2. Open generated report path and identify failed sections:
   - command availability
   - dotfile mismatch
   - function mismatch
   - strict contract drift (manifest vs state snapshot)

## Promote and Layering Issues

1. Confirm resolved target and host:
   - `./bin/ossetup install --dry-run --target auto --host auto`
2. Validate state snapshot files for target:
   - `ls -la manifests/state/<target>/`
3. Preview promote without mutating:
   - `./bin/ossetup promote --target <target> --scope all --from-state latest --preview`

## Escalation Data to Capture

1. Command executed.
2. Full stderr/stdout.
3. Relevant manifest snippets.
4. Current commit hash.
5. Report artifact path (if verify/doctor involved).
