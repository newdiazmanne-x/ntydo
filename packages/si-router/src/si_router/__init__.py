"""NTYDO SI auto-aware computability router."""

__all__ = ["route_workload"]


def route_workload(task_tokens: int, distributed_ranks: int, allow_cloud: bool) -> dict[str, object]:
    """Select an execution tier based on workload size, MPI rank count, and cloud permission."""
    if allow_cloud and task_tokens >= 16384:
        return {
            "tier": 3,
            "mode": "cloud-google-ai-scale",
            "hitl_required": True,
            "reason": "High token volume with explicit cloud permission enabled",
        }
    if distributed_ranks > 1:
        return {
            "tier": 2,
            "mode": "openmpi-llvm-fused",
            "hitl_required": True,
            "reason": f"Multi-rank execution across {distributed_ranks} ranks with fused kernels",
        }
    if task_tokens >= 4096:
        return {
            "tier": 1,
            "mode": "sparse-moe-local-or-lan",
            "hitl_required": False,
            "reason": "Moderate context suited to sparse top-k MoE routing",
        }
    return {
        "tier": 0,
        "mode": "edge-termux-deterministic",
        "hitl_required": False,
        "reason": "Low-latency local edge execution on aarch64",
    }
