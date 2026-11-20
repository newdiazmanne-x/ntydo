"""NTYDO SI auto-aware computability router."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

__all__ = ["DEFAULT_THRESHOLDS", "load_routing_config", "route_workload"]

DEFAULT_THRESHOLDS: dict[str, int] = {
    "tier1_tokens": 4096,
    "tier3_tokens": 16384,
}


def _default_spec_path() -> Path:
    """Resolve repo-root docs/auto-aware-computability.machine.json from package path."""
    return Path(__file__).resolve().parents[4] / "docs" / "auto-aware-computability.machine.json"


def _parse_positive_int(value: Any, fallback: int) -> int:
    if isinstance(value, bool):
        return fallback
    if isinstance(value, int) and value > 0:
        return value
    return fallback


def load_routing_config(spec_path: Path | str | None = None) -> dict[str, int]:
    """Load routing thresholds from machine JSON with safe fallback defaults."""
    thresholds = dict(DEFAULT_THRESHOLDS)
    target = Path(spec_path) if spec_path is not None else _default_spec_path()

    try:
        raw = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return thresholds

    if not isinstance(raw, dict):
        return thresholds

    # Optional direct overrides if present in machine JSON
    routing_cfg = raw.get("routing_thresholds")
    if isinstance(routing_cfg, dict):
        thresholds["tier1_tokens"] = _parse_positive_int(
            routing_cfg.get("tier1_tokens"), thresholds["tier1_tokens"]
        )
        thresholds["tier3_tokens"] = _parse_positive_int(
            routing_cfg.get("tier3_tokens"), thresholds["tier3_tokens"]
        )

    # Optional scaling_hierarchy overrides if tier token thresholds are specified
    hierarchy = raw.get("scaling_hierarchy")
    if isinstance(hierarchy, list):
        for entry in hierarchy:
            if not isinstance(entry, dict):
                continue
            tier = entry.get("tier")
            min_tokens = entry.get("min_tokens")
            if tier == 1:
                thresholds["tier1_tokens"] = _parse_positive_int(
                    min_tokens, thresholds["tier1_tokens"]
                )
            elif tier == 3:
                thresholds["tier3_tokens"] = _parse_positive_int(
                    min_tokens, thresholds["tier3_tokens"]
                )

    if thresholds["tier3_tokens"] < thresholds["tier1_tokens"]:
        thresholds["tier3_tokens"] = thresholds["tier1_tokens"]

    return thresholds


def route_workload(
    task_tokens: int,
    distributed_ranks: int,
    allow_cloud: bool,
    thresholds: dict[str, int] | None = None,
    spec_path: Path | str | None = None,
) -> dict[str, object]:
    """Select an execution tier based on workload size, MPI rank count, and cloud permission."""
    cfg = dict(DEFAULT_THRESHOLDS)
    if spec_path is not None or thresholds is None:
        cfg.update(load_routing_config(spec_path))
    if thresholds is not None:
        cfg["tier1_tokens"] = _parse_positive_int(
            thresholds.get("tier1_tokens"), cfg["tier1_tokens"]
        )
        cfg["tier3_tokens"] = _parse_positive_int(
            thresholds.get("tier3_tokens"), cfg["tier3_tokens"]
        )

    tier1_min = cfg["tier1_tokens"]
    tier3_min = cfg["tier3_tokens"]

    if allow_cloud and task_tokens >= tier3_min:
        return {
            "tier": 3,
            "mode": "cloud-google-ai-scale",
            "hitl_required": True,
            "thresholds": cfg,
            "reason": f"Token count ({task_tokens}) >= tier3 threshold ({tier3_min}) with cloud enabled",
        }
    if distributed_ranks > 1:
        return {
            "tier": 2,
            "mode": "openmpi-llvm-fused",
            "hitl_required": True,
            "thresholds": cfg,
            "reason": f"Multi-rank execution across {distributed_ranks} ranks with fused kernels",
        }
    if task_tokens >= tier1_min:
        return {
            "tier": 1,
            "mode": "sparse-moe-local-or-lan",
            "hitl_required": False,
            "thresholds": cfg,
            "reason": f"Token count ({task_tokens}) >= tier1 threshold ({tier1_min}) suited to sparse top-k MoE",
        }
    return {
        "tier": 0,
        "mode": "edge-termux-deterministic",
        "hitl_required": False,
        "thresholds": cfg,
        "reason": "Low-latency local edge execution on aarch64",
    }
