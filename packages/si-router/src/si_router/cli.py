"""CLI entrypoint for si-router."""

import argparse
import json
import sys

from si_router import route_workload


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="si-router",
        description="Evaluate SI auto-aware computability routing tier.",
    )
    parser.add_argument("--tokens", type=int, default=1024, help="Estimated workload token count")
    parser.add_argument("--ranks", type=int, default=1, help="Available MPI/compute ranks")
    parser.add_argument(
        "--allow-cloud",
        action="store_true",
        help="Permit Tier 3 cloud/Google AI escalation when thresholds are met",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    decision = route_workload(
        task_tokens=max(0, args.tokens),
        distributed_ranks=max(1, args.ranks),
        allow_cloud=args.allow_cloud,
    )
    print(json.dumps(decision, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
