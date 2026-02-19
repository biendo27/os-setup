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
for f in manifests/*.yaml manifests/profiles/*.yaml manifests/targets/*.yaml; do
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
2. Open generated report path and identify failed sections:
   - command availability
   - dotfile mismatch
   - function mismatch

## Escalation Data to Capture

1. Command executed.
2. Full stderr/stdout.
3. Relevant manifest snippets.
4. Current commit hash.
5. Report artifact path (if verify/doctor involved).
