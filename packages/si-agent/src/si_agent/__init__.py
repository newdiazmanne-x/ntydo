"""Cross-platform local-first SI agent loop with HITL gating."""

from __future__ import annotations

import json
import os
import platform
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

__all__ = ["run_local_agent"]


def _resolve_log_dir(log_dir: str | Path | None = None) -> Path:
    if log_dir is not None:
        return Path(log_dir)
    sandbox_home = os.environ.get("NYDO_SANDBOX_HOME")
    if sandbox_home:
        return Path(sandbox_home) / "logs"
    return Path.home() / ".local" / "share" / "nydo-agent-logs"


def _local_route_decision(tokens: int, ranks: int, allow_cloud: bool) -> dict[str, Any]:
    """Zero-cloud-infra local routing policy matching NTYDO tiers 0-3."""
    if allow_cloud and tokens >= 16384:
        return {
            "tier": 3,
            "mode": "cloud-google-ai-scale",
            "hitl_required": True,
            "reason": "Cloud escalation requested and token threshold reached",
        }
    if ranks > 1:
        return {
            "tier": 2,
            "mode": "openmpi-llvm-fused",
            "hitl_required": True,
            "reason": f"Multi-rank execution requested across {ranks} ranks",
        }
    if tokens >= 4096:
        return {
            "tier": 1,
            "mode": "sparse-moe-local-or-lan",
            "hitl_required": False,
            "reason": "Local/LAN sparse MoE path without cloud hardware",
        }
    return {
        "tier": 0,
        "mode": "edge-termux-deterministic",
        "hitl_required": False,
        "reason": "Free local deterministic execution on current host",
    }


def run_local_agent(
    goal: str,
    tokens: int = 512,
    ranks: int = 1,
    allow_cloud: bool = False,
    approve_hitl: bool = False,
    log_dir: str | Path | None = None,
) -> dict[str, Any]:
    """Execute a local, zero-cost agent plan with explicit HITL gating and JSON audit log."""
    route = _local_route_decision(tokens=tokens, ranks=ranks, allow_cloud=allow_cloud)
    needs_approval = bool(route["hitl_required"]) and not approve_hitl

    status = "awaiting_hitl_approval" if needs_approval else "completed_local_dry_run"
    record: dict[str, Any] = {
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "host": {
            "system": platform.system(),
            "machine": platform.machine(),
            "python": platform.python_version(),
        },
        "goal": goal,
        "routing": route,
        "hitl_approved": approve_hitl,
        "status": status,
        "cost_usd_estimate": 0.0,
    }

    target_dir = _resolve_log_dir(log_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    log_file = target_dir / "si-agent-runs.jsonl"
    with log_file.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record) + "\n")

    record["log_file"] = str(log_file)
    return record
