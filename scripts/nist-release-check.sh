#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${NYDO_RELEASE_EVIDENCE_DIR:-${TMPDIR:-/tmp}/nydo-nist-evidence}"
mkdir -p "$OUT_DIR"

TMP_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nydo-uv-wheels.XXXXXX")"
trap 'rm -rf "$TMP_BUILD_DIR"' EXIT

echo "[1/6] NIST SSDF (PO/PS) — Security & secrets check..."
"$REPO_ROOT/scripts/security-check.sh"

echo "[2/6] NIST SSDF (PW) & SP 800-53 (SA-10) — JSON spec validation..."
"$REPO_ROOT/scripts/validate-json-specs.sh"

echo "[3/6] NIST SSDF (PW) & SP 800-53 (SA-11) — Package smoke & unit tests..."
"$REPO_ROOT/scripts/smoke-test-packages.sh"

echo "[4/6] NIST SP 800-53 (SA-12) — Building wheels via uv build into temp dir..."
WHEELS_OUT_DIR="$OUT_DIR/wheels"
mkdir -p "$WHEELS_OUT_DIR"
rm -f "$WHEELS_OUT_DIR"/*.whl

built_wheels=0
for pkg_path in "$REPO_ROOT/packages"/*; do
  [ -d "$pkg_path" ] || continue
  [ -f "$pkg_path/pyproject.toml" ] || continue

  pkg_name="$(basename "$pkg_path")"
  pkg_tmp_out="$TMP_BUILD_DIR/$pkg_name"
  mkdir -p "$pkg_tmp_out"

  echo "  -> Building wheel for $pkg_name..."
  uv build --wheel --out-dir "$pkg_tmp_out" "$pkg_path"

  for whl in "$pkg_tmp_out"/*.whl; do
    [ -f "$whl" ] || continue
    cp "$whl" "$WHEELS_OUT_DIR/"
    built_wheels=$((built_wheels + 1))
  done
done

if [ "$built_wheels" -eq 0 ]; then
  echo "[-] No wheels were built under $REPO_ROOT/packages" >&2
  exit 1
fi

WHEELS_SHA_FILE="$OUT_DIR/wheels.sha256"
(
  cd "$WHEELS_OUT_DIR"
  LC_ALL=C sha256sum ./*.whl
) > "$WHEELS_SHA_FILE"

echo "[5/6] NIST SP 800-53 (SA-12) — Generating source integrity manifest..."
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

echo "[6/6] NIST SP 800-53 (SA-12) — Verifying SHA-256 manifests..."
(
  cd "$REPO_ROOT"
  LC_ALL=C sha256sum -c "$MANIFEST_FILE" --status
)
echo "  -> Verified source manifest: $MANIFEST_FILE"

(
  cd "$WHEELS_OUT_DIR"
  LC_ALL=C sha256sum -c "$WHEELS_SHA_FILE"
)
echo "  -> Verified wheel checksums: $WHEELS_SHA_FILE"

echo "[+] NIST verification, wheel build, and checksum checks passed ($built_wheels wheel(s))."
echo "    Source manifest : $MANIFEST_FILE"
echo "    Wheels dir      : $WHEELS_OUT_DIR"
echo "    Wheel checksums : $WHEELS_SHA_FILE"
