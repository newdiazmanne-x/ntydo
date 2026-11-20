---
name: moe-router-openmpi
description: Mixture-of-Experts (MoE) routing, token-to-expert load balancing, and OpenMPI distributed rank topology planning.
---

# MoE Routing & OpenMPI Scaling Skill

## First-Principles Contract
- **Explicit Expert Topologies:** Declare total experts `E`, active experts per token `K`, capacity factor `C`, and MPI rank mapping (`world_size`, `rank`, `local_rank`) before execution.
- **Bounded Droppage & Skew:** Track token drop rate and expert load imbalance; fall back deterministically to local/dense or smaller active `K` when ranks are saturated.
- **Termux-Safe Control Plane:** On Termux (`aarch64`), generate and validate routing plans and MPI hostfiles/manifests locally; execute heavy multi-rank `mpirun` / `orterun` workloads on Linux/cluster nodes with explicit HITL approval.

## Workflow
1. Inspect available compute ranks, memory headroom, and network reachability (never exposing tokens or secrets).
2. Emit a deterministic MoE + OpenMPI execution plan (expert shard map, collective communication pattern such as `AlltoAll`, and fallback tier).
3. Require explicit human approval before launching multi-node MPI jobs or changing remote cluster state.
