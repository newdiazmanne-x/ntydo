# NTYDO Reproducibility, CI/CD & Release SOP

Copyright (c) 2026 **Emmanuel Díaz Ortega**. All rights reserved.  
Contact: `newdiazmanne@gmail.com`

## 1. Local-First & Zero-Cost Rules
- Run locally via `uv` with `UV_LINK_MODE=copy` on Termux (`aarch64`) and desktop without requiring paid services.
- Keep secrets outside the repository under `~/.secrets/` (`700` directory, `600` files); never commit credentials or embed them in web/QR targets.
- Require explicit Human-in-the-Loop (HITL) approval before replacing `index.html`, publishing releases, or launching public campaigns.

## 2. Editions & Licensing
- **Free Edition ($0):** Public repository workflow for local execution, testing, and verification under attribution to **Emmanuel Díaz Ortega**.
- **Pro Edition (By Inquiry):** Custom commercial licensing, multi-rank/campaign playbooks, and support arrangements via `newdiazmanne@gmail.com`.

## 3. Verification Commands
- Install prerequisites on Termux if `uv` is missing:
  ```bash
  pkg install -y git python uv
  ```
- Smoke tests (`--json` IS valid here):
  ```bash
  ./scripts/smoke-test-packages.sh --json
  ```
  Expected: `{"status": "ok", "tested": 3, "passed": 3, "failed": 0}`.
- NIST release check (no `--json` flag — the script rejects it):
  ```bash
  ./scripts/nist-release-check.sh
  ```
  Expected: all 6 steps pass, 3 wheels built, SHA-256 manifests verified.
  Evidence: `${NYDO_RELEASE_EVIDENCE_DIR:-/tmp/nydo-nist-evidence}`.
- Verify existing evidence without rebuilding:
  ```bash
  ./scripts/nist-release-check.sh --verify-only
  ```

## 4. CI/CD — GitHub Actions
- Workflow: `.github/workflows/nist-release-check.yml`
- Triggers: push to `main`, tags `v*`. Runner: `ubuntu-latest`, Python 3.12, `uv` via `astral-sh/setup-uv@v4`.
- Verified 2026-11-20: run #2 on commit `3c97c21` passed in 12 s.
- Check runs: `https://github.com/newdiazmanne-x/ntydo/actions`

## 5. Release Flow
- Run §3 locally, get HITL approval, then tag and push:
  ```bash
  git tag -a vX.Y.Z -m "Release vX.Y.Z"
  git push origin vX.Y.Z
  ```

## 6. Known Gotchas
- `nist-release-check.sh` takes NO `--json` (only `--verify-only`).
- If `uv` is missing, all packages fail with exit 127.
- On Termux install `uv` with `pkg install uv` — `pip install uv` fails (no Android wheel).
- GitHub Pages is not enabled yet; enable in repo Settings → Pages → Deploy from a branch, `main`, `/ (root)`.
