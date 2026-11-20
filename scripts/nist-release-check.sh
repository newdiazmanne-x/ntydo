#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${NYDO_RELEASE_EVIDENCE_DIR:-${TMPDIR:-/tmp}/nydo-nist-evidence}"
mkdir -p "$OUT_DIR"

echo "[1/4] NIST SSDF (PO/PS) — Security & secrets check..."
"$REPO_ROOT/scripts/security-check.sh"

echo "[2/4] NIST SSDF (PW) & SP 800-53 (SA-10) — JSON spec validation..."
"$REPO_ROOT/scripts/validate-json-specs.sh"

echo "[3/4] NIST SSDF (PW) & SP 800-53 (SA-11) — Package smoke & unit tests..."
"$REPO_ROOT/scripts/smoke-test-packages.sh"

echo "[4/4] NIST SP 800-53 (SA-12) — Generating local SHA-256 integrity manifest..."
MANIFEST_FILE="$OUT_DIR/ntydo-manifest.sha256"
(
  cd "$REPO_ROOT"
  find packages scripts docs mcp -type f \
    -not -path '*/.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.pytest_cache/*' \
    | LC_ALL=C sort \
    | xargs sha256sum
) > "$MANIFEST_FILE"

echo "[+] NIST verification passed. SHA-256 manifest written to: $MANIFEST_FILE"
