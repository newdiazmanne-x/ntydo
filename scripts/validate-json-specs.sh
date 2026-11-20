#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$REPO_ROOT" <<'PY'
import json
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
targets = [
    repo_root / "docs" / "si-first-principles.machine.json",
    repo_root / "docs" / "auto-aware-computability.machine.json",
    repo_root / "mcp" / "mcp.json",
]

errors: list[str] = []

for path in targets:
    if not path.is_file():
        errors.append(f"Missing required JSON file: {path.relative_to(repo_root)}")
        continue

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        errors.append(f"Invalid JSON in {path.relative_to(repo_root)}: {exc}")
        continue

    if not isinstance(data, dict):
        errors.append(f"Top-level JSON must be an object in {path.relative_to(repo_root)}")
        continue

    rel = path.relative_to(repo_root)

    if rel.name == "mcp.json":
        servers = data.get("mcpServers")
        if not isinstance(servers, dict) or not servers:
            errors.append(f"{rel}: 'mcpServers' must be a non-empty object")
        else:
            for srv_name, srv_cfg in servers.items():
                if not isinstance(srv_cfg, dict) or not isinstance(srv_cfg.get("command"), str) or not srv_cfg["command"].strip():
                    errors.append(f"{rel}: server '{srv_name}' must define a non-empty string 'command'")

    if rel.name == "auto-aware-computability.machine.json":
        thresholds = data.get("routing_thresholds")
        if thresholds is not None:
            if not isinstance(thresholds, dict):
                errors.append(f"{rel}: 'routing_thresholds' must be an object")
            else:
                for key in ("tier1_tokens", "tier3_tokens"):
                    if key in thresholds:
                        val = thresholds[key]
                        if isinstance(val, bool) or not isinstance(val, int) or val <= 0:
                            errors.append(f"{rel}: 'routing_thresholds.{key}' must be a positive integer")

if errors:
    for err in errors:
        print(f"[-] {err}", file=sys.stderr)
    sys.exit(1)

print(f"[+] Validated {len(targets)} JSON spec files cleanly.")
PY
