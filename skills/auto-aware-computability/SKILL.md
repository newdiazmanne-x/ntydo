---
name: auto-aware-computability
description: Auto-aware computability policy selecting exact, quantized, sparse MoE, local, or cloud/Google AI inference paths under strict SI & HITL guardrails.
---

# Auto-Aware Computability Skill

## Core Principle
**Auto-Aware Computability** means the runtime continuously evaluates *what is computable within current latency, memory, thermal, and rank budgets*—and automatically selects the highest-fidelity execution mode that satisfies constraints without violating security or human-in-the-loop (HITL) boundaries.

## Escalation & Degradation Ladder
1. **Tier 0 — Local Deterministic / Fast Path (Termux / Edge):** Local scripts, `uv` + `hatchling` workers, or compact local models when latency is tight, offline/edge is required, or payload is small.
2. **Tier 1 — Sparse MoE / Quantized Local or LAN:** Activate sparse expert subsets (`top-k`) and quantized weights when memory/bandwidth allows higher capability without cloud round-trip cost.
3. **Tier 2 — Distributed OpenMPI + Fused LLVM Kernels:** Shard experts/tensors across MPI ranks with fused kernels when throughput or context/batch scale exceeds single-node capacity.
4. **Tier 3 — Cloud / Google AI Scale-Out:** Escalate heavy training, large-context synthesis, or frontier reasoning to remote/Google AI infrastructure only when explicitly permitted, with secrets strictly in `~/.secrets/` (`0600`) and HITL approval for external/cost/network side effects.

## Guardrails
- Never commit secrets (`tskey-*`, API keys, `.env`) to `~/ntydo`.
- Pause at HITL gates before external egress, remote execution, or Git push.
