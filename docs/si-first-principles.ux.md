# Synthetic Intelligence (SI) First Principles — Human-in-the-Loop (HITL) UX

## Design Goal
Keep the human operator in clear command of high-consequence actions while letting automated scripts and local ML inference handle repeatable inspection, drafting, and checks.

## HITL Interaction Loop
1. **Observe (Read-Only First):** Run diagnostic or status commands (`./scripts/whoami-check.sh`, `./scripts/nydo-sandbox.sh status`, `git status -sb`) before mutating state.
2. **Propose (Scoped Plan):** Present exact target paths, commands, and expected side effects.
3. **Gate (Explicit Approval):** Pause for human confirmation before:
   - Modifying firewall/Tailscale/SSH/network exposure
   - Committing or pushing changes to `origin`
   - Deleting files or resetting sandbox state
4. **Execute (Sandboxed & Logged):** Run inside `./scripts/nydo-sandbox.sh` or `./scripts/uv-pipeline.sh` with `set -euo pipefail`.
5. **Verify (Observable Proof):** Confirm exit code `0`, clean `git status`, and expected output before advancing.

## Operator Controls
- **Abort / Hold:** `Ctrl+C` or stop before approval gate if output or diff looks unexpected.
- **Isolate:** Run experiments under `./scripts/nydo-sandbox.sh run ...` so `~/ntydo` stays clean.
- **Audit:** Inspect `git diff` and `git status --short` prior to any commit.
