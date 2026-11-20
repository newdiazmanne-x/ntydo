"""CLI entrypoint for si-agent."""

from __future__ import annotations

import argparse
import json
import sys

from si_agent import run_local_agent


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="si-agent",
        description="Run a cross-platform local-first NTYDO agent step with HITL gating.",
    )
    parser.add_argument("--goal", type=str, default="Inspect local workspace health", help="Agent task goal")
    parser.add_argument("--tokens", type=int, default=512, help="Estimated token budget")
    parser.add_argument("--ranks", type=int, default=1, help="Compute ranks")
    parser.add_argument("--allow-cloud", action="store_true", help="Allow Tier 3 cloud path evaluation")
    parser.add_argument("--approve-hitl", action="store_true", help="Mark HITL gate as approved")
    parser.add_argument("--log-dir", type=str, default=None, help="Optional directory for JSONL run logs")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    result = run_local_agent(
        goal=args.goal,
        tokens=max(0, args.tokens),
        ranks=max(1, args.ranks),
        allow_cloud=args.allow_cloud,
        approve_hitl=args.approve_hitl,
        log_dir=args.log_dir,
    )
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
