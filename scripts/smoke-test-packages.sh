#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"
PIPELINE_SCRIPT="$REPO_ROOT/scripts/uv-pipeline.sh"

if [ ! -x "$PIPELINE_SCRIPT" ]; then
  echo "[-] Missing executable pipeline script: $PIPELINE_SCRIPT" >&2
  exit 1
fi

if [ ! -d "$PACKAGES_DIR" ]; then
  echo "[-] Packages directory not found: $PACKAGES_DIR" >&2
  exit 1
fi

tested_count=0

for pkg_path in "$PACKAGES_DIR"/*; do
  [ -d "$pkg_path" ] || continue
  [ -f "$pkg_path/pyproject.toml" ] || continue

  pkg_name="$(basename "$pkg_path")"
  tested_count=$((tested_count + 1))

  echo "=========================================="
  echo "[*] Smoke-testing package: $pkg_name"
  echo "=========================================="

  if [ -d "$pkg_path/tests" ]; then
    "$PIPELINE_SCRIPT" "$pkg_name" python -m unittest discover -s "packages/$pkg_name/tests" -v
  else
    echo "[!] No tests/ directory in packages/$pkg_name; running lock/sync check only."
    "$PIPELINE_SCRIPT" "$pkg_name"
  fi
done

if [ "$tested_count" -eq 0 ]; then
  echo "[-] No packages with pyproject.toml found under $PACKAGES_DIR" >&2
  exit 1
fi

echo "[+] Smoke tests completed across $tested_count package(s)."
