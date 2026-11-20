#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${NYDO_RELEASE_EVIDENCE_DIR:-${TMPDIR:-/tmp}/nydo-nist-evidence}"
VERIFY_ONLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --verify-only)
      VERIFY_ONLY=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/nist-release-check.sh [--verify-only]

Runs NIST-aligned security, JSON spec, package smoke-test, wheel build, and
SHA-256 manifest checks, or verifies existing manifests when --verify-only is passed.
EOF
      exit 0
      ;;
    *)
      echo "[-] Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

write_sha256_manifest() {
  local base_dir="$1"
  local manifest_path="$2"
  shift 2

  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$base_dir"
      LC_ALL=C sha256sum "$@"
    ) > "$manifest_path"
  else
    python3 - "$base_dir" "$manifest_path" "$@" <<'PY'
import hashlib
import sys
from pathlib import Path

base_dir = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
rel_files = sys.argv[3:]

lines: list[str] = []
for rel in rel_files:
    target = base_dir / rel
    if not target.is_file():
        print(f"[-] Missing file for checksum: {target}", file=sys.stderr)
        sys.exit(1)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    lines.append(f"{digest}  {rel}")

manifest_path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
PY
  fi
}

verify_sha256_manifest() {
  local base_dir="$1"
  local manifest_path="$2"

  if [ ! -f "$manifest_path" ]; then
    echo "[-] Missing manifest file: $manifest_path" >&2
    exit 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$base_dir"
      LC_ALL=C sha256sum -c "$manifest_path" --status
    )
  else
    python3 - "$base_dir" "$manifest_path" <<'PY'
import hashlib
import sys
from pathlib import Path

base_dir = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])

for line_no, raw_line in enumerate(manifest_path.read_text(encoding="utf-8").splitlines(), start=1):
    line = raw_line.strip()
    if not line:
        continue
    parts = line.split(maxsplit=1)
    if len(parts) != 2:
        print(f"[-] Malformed checksum line {line_no} in {manifest_path}", file=sys.stderr)
        sys.exit(1)
    expected_digest, rel_path = parts[0].lower(), parts[1].lstrip("./")
    target = base_dir / rel_path
    if not target.is_file():
        print(f"[-] Missing artifact '{rel_path}' listed in {manifest_path}", file=sys.stderr)
        sys.exit(1)
    actual_digest = hashlib.sha256(target.read_bytes()).hexdigest()
    if actual_digest != expected_digest:
        print(f"[-] Checksum mismatch for '{rel_path}' in {manifest_path}", file=sys.stderr)
        sys.exit(1)
PY
  fi
}

MANIFEST_FILE="$OUT_DIR/ntydo-manifest.sha256"
WHEELS_OUT_DIR="$OUT_DIR/wheels"
WHEELS_SHA_FILE="$OUT_DIR/wheels.sha256"

if [ "$VERIFY_ONLY" -eq 1 ]; then
  echo "[*] NIST SP 800-53 (SA-12) — Verifying existing manifests (--verify-only)..."
  verify_sha256_manifest "$REPO_ROOT" "$MANIFEST_FILE"
  echo "  -> Verified source manifest: $MANIFEST_FILE"

  verify_sha256_manifest "$WHEELS_OUT_DIR" "$WHEELS_SHA_FILE"
  echo "  -> Verified wheel checksums: $WHEELS_SHA_FILE"

  echo "[+] Existing SHA-256 manifests verified cleanly."
  exit 0
fi

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

wheel_rel_names=()
for whl in "$WHEELS_OUT_DIR"/*.whl; do
  [ -f "$whl" ] || continue
  wheel_rel_names+=("$(basename "$whl")")
done
write_sha256_manifest "$WHEELS_OUT_DIR" "$WHEELS_SHA_FILE" "${wheel_rel_names[@]}"

echo "[5/6] NIST SP 800-53 (SA-12) — Generating source integrity manifest..."
source_rel_files=()
while IFS= read -r rel_file; do
  source_rel_files+=("$rel_file")
done < <(
  cd "$REPO_ROOT"
  find packages scripts docs mcp -type f \
    -not -path '*/.venv/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/.pytest_cache/*' \
    | LC_ALL=C sort
)
write_sha256_manifest "$REPO_ROOT" "$MANIFEST_FILE" "${source_rel_files[@]}"

echo "[6/6] NIST SP 800-53 (SA-12) — Verifying SHA-256 manifests..."
verify_sha256_manifest "$REPO_ROOT" "$MANIFEST_FILE"
echo "  -> Verified source manifest: $MANIFEST_FILE"

verify_sha256_manifest "$WHEELS_OUT_DIR" "$WHEELS_SHA_FILE"
echo "  -> Verified wheel checksums: $WHEELS_SHA_FILE"

echo "[+] NIST verification, wheel build, and checksum checks passed ($built_wheels wheel(s))."
echo "    Source manifest : $MANIFEST_FILE"
echo "    Wheels dir      : $WHEELS_OUT_DIR"
echo "    Wheel checksums : $WHEELS_SHA_FILE"
