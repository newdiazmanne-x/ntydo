#!/usr/bin/env bash
set -euo pipefail

SANDBOX_HOME="${NYDO_SANDBOX_HOME:-$HOME/.local/share/nydo-sandbox}"
SANDBOX_TMP="${NYDO_SANDBOX_TMP:-${TMPDIR:-/tmp}/nydo-sandbox}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$SANDBOX_HOME/work" "$SANDBOX_HOME/logs" "$SANDBOX_TMP"
chmod 700 "$SANDBOX_HOME"

cmd="${1:-status}"
shift || true

case "$cmd" in
  status)
    echo "=== NYDO SANDBOX STATUS ==="
    echo "Repo root:    $REPO_ROOT"
    echo "Sandbox home: $SANDBOX_HOME"
    echo "Sandbox tmp:  $SANDBOX_TMP"
    ls -la "$SANDBOX_HOME/work"
    ;;
  reset)
    rm -rf "$SANDBOX_HOME/work"/* "$SANDBOX_TMP"/*
    echo "[+] NYDO sandbox work and tmp directories reset."
    ;;
  run)
    if [ "$#" -lt 1 ]; then
      echo "Usage: $0 run <command...>" >&2
      exit 1
    fi
    (
      cd "$SANDBOX_HOME/work"
      export HOME="$SANDBOX_HOME"
      export TMPDIR="$SANDBOX_TMP"
      export UV_LINK_MODE=copy
      "$@"
    )
    ;;
  *)
    echo "Usage: $0 {status|reset|run <command...>}" >&2
    exit 1
    ;;
esac
