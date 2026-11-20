# NTYDO Editions, Publishing & Compliance Guide

**Author & Copyright Holder:** Emmanuel Díaz Ortega — All rights reserved.

## 1. Publishing via `uv` + GitHub Pages
1. **Verify locally first:** Run `./scripts/nist-release-check.sh --json` so security checks, JSON spec validation, package unit tests, wheel builds, and SHA-256 checksum verification pass.
2. **Host web quick-start on GitHub Pages:** Serve `index.html` from `main` branch `/` (root) at `https://newdiazmanne-x.github.io/ntydo/`.
3. **Distribute `uv` packages cleanly:** Use `UV_LINK_MODE=copy` with `uv` (`hatchling` backend) across Termux and desktop environments, attaching built `.whl` files and `wheels.sha256` / `ntydo-manifest.sha256` manifests to GitHub Releases.

## 2. Free vs. Pro Tier Matrix
| Capability | Free Edition | Pro Edition |
| :--- | :--- | :--- |
| `uv` (`hatchling`) local packages (`core-py`, `si-router`, `si-agent`) | Included | Included |
| Termux (`aarch64`) & desktop sandbox (`nydo-sandbox.sh`) | Included | Included |
| NIST-aligned verification (`security-check.sh`, `validate-json-specs.sh`, `nist-release-check.sh`) | Included | Included |
| Commercial campaign playbooks, custom SLA & multi-node orchestration packs | Not included | Licensed via Emmanuel Díaz Ortega (`newdiazmanne@gmail.com`) |

## 3. Human-in-the-Loop (HITL) & Campaign Guardrails
- Always keep a human in the loop before publishing releases, launching public campaigns, or executing privileged commands.
- Keep secrets strictly out of Git, QR codes, and public web pages (`~/.secrets/` with `0600` permissions).
