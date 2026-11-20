#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"

usage() {
  cat <<'EOF'
Usage: ./scripts/uv-pipeline.sh <package-name> [entrypoint-or-command...]

Examples:
  ./scripts/uv-pipeline.sh core-py app
  ./scripts/uv-pipeline.sh core-py python -m unittest discover -s tests
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

PKG_NAME="${1:-core-py}"
shift || true

PKG_DIR="$PACKAGES_DIR/$PKG_NAME"
PYPROJECT="$PKG_DIR/pyproject.toml"

if [ ! -f "$PYPROJECT" ]; then
  echo "[-] Missing pyproject.toml for package '$PKG_NAME' at: $PYPROJECT" >&2
  exit 1
fi

if ! grep -q 'hatchling\.build' "$PYPROJECT"; then
  echo "[-] Guardrail: packages/$PKG_NAME must use hatchling.build for Termux compatibility." >&2
  exit 1
fi

echo "[1/3] Locking dependencies for packages/$PKG_NAME (UV_LINK_MODE=$UV_LINK_MODE)..."
uv lock --project "$PKG_DIR"

echo "[2/3] Syncing environment for packages/$PKG_NAME..."
uv sync --project "$PKG_DIR"

if [ "$#" -gt 0 ]; then
  echo "[3/3] Running in packages/$PKG_NAME: $*"
  uv run --project "$PKG_DIR" "$@"
else
  echo "[3/3] Lock and sync complete for packages/$PKG_NAME."
fi
