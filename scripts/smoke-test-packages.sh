#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"
PIPELINE_SCRIPT="$REPO_ROOT/scripts/uv-pipeline.sh"

JSON_MODE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json)
      JSON_MODE=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/smoke-test-packages.sh [--json]

Runs unit tests (or lock/sync checks when tests/ is absent) across all
packages under packages/ using ./scripts/uv-pipeline.sh.
EOF
      exit 0
      ;;
    *)
      echo "[-] Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

log_info() {
  if [ "$JSON_MODE" -eq 0 ]; then
    printf '%s\n' "$1"
  fi
}

if [ ! -x "$PIPELINE_SCRIPT" ]; then
  echo "[-] Missing executable pipeline script: $PIPELINE_SCRIPT" >&2
  exit 1
fi

if [ ! -d "$PACKAGES_DIR" ]; then
  echo "[-] Packages directory not found: $PACKAGES_DIR" >&2
  exit 1
fi

TMP_LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nydo-smoke.XXXXXX")"
RESULTS_JSONL="$TMP_LOG_DIR/results.jsonl"
touch "$RESULTS_JSONL"
trap 'rm -rf "$TMP_LOG_DIR"' EXIT

tested_count=0
passed_count=0
failed_count=0
overall_status="ok"

for pkg_path in "$PACKAGES_DIR"/*; do
  [ -d "$pkg_path" ] || continue
  [ -f "$pkg_path/pyproject.toml" ] || continue

  pkg_name="$(basename "$pkg_path")"
  tested_count=$((tested_count + 1))
  pkg_log="$TMP_LOG_DIR/${pkg_name}.log"

  log_info "=========================================="
  log_info "[*] Smoke-testing package: $pkg_name"
  log_info "=========================================="

  set +e
  if [ -d "$pkg_path/tests" ]; then
    mode="unittest"
    if [ "$JSON_MODE" -eq 1 ]; then
      "$PIPELINE_SCRIPT" "$pkg_name" python -m unittest discover -s "packages/$pkg_name/tests" -v >"$pkg_log" 2>&1
      rc=$?
    else
      "$PIPELINE_SCRIPT" "$pkg_name" python -m unittest discover -s "packages/$pkg_name/tests" -v | tee "$pkg_log"
      rc=${PIPESTATUS[0]}
    fi
  else
    mode="sync-only"
    log_info "[!] No tests/ directory in packages/$pkg_name; running lock/sync check only."
    if [ "$JSON_MODE" -eq 1 ]; then
      "$PIPELINE_SCRIPT" "$pkg_name" >"$pkg_log" 2>&1
      rc=$?
    else
      "$PIPELINE_SCRIPT" "$pkg_name" | tee "$pkg_log"
      rc=${PIPESTATUS[0]}
    fi
  fi
  set -e

  if [ "$rc" -eq 0 ]; then
    pkg_status="passed"
    passed_count=$((passed_count + 1))
  else
    pkg_status="failed"
    failed_count=$((failed_count + 1))
    overall_status="failed"
  fi

  python3 - "$RESULTS_JSONL" "$pkg_name" "$mode" "$pkg_status" "$rc" <<'PY'
import json
import sys

jsonl_path, name, mode, status, rc_str = sys.argv[1:]
entry = {
    "package": name,
    "mode": mode,
    "status": status,
    "exit_code": int(rc_str),
}
with open(jsonl_path, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(entry) + "\n")
PY

  if [ "$failed_count" -gt 0 ] && [ "$JSON_MODE" -eq 0 ]; then
    break
  fi
done

if [ "$tested_count" -eq 0 ]; then
  overall_status="failed"
fi

if [ "$JSON_MODE" -eq 1 ]; then
  python3 - "$RESULTS_JSONL" "$overall_status" "$tested_count" "$passed_count" "$failed_count" "$UV_LINK_MODE" <<'PY'
import json
import sys

jsonl_path, status, tested, passed, failed, link_mode = sys.argv[1:]
packages = []
with open(jsonl_path, encoding="utf-8") as fh:
    for line in fh:
        line = line.strip()
        if line:
            packages.append(json.loads(line))

summary = {
    "status": status,
    "uv_link_mode": link_mode,
    "tested": int(tested),
    "passed": int(passed),
    "failed": int(failed),
    "packages": packages,
}
print(json.dumps(summary, indent=2))
PY
else
  if [ "$tested_count" -eq 0 ]; then
    echo "[-] No packages with pyproject.toml found under $PACKAGES_DIR" >&2
    exit 1
  fi
  if [ "$failed_count" -gt 0 ]; then
    echo "[-] Smoke tests failed ($failed_count of $tested_count package(s) failed)." >&2
    exit 1
  fi
  echo "[+] Smoke tests completed across $tested_count package(s)."
fi

if [ "$overall_status" != "ok" ]; then
  exit 1
fi
