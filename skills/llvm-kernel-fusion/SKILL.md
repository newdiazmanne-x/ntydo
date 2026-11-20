---
name: llvm-kernel-fusion
description: Kernel-to-kernel fusion, LLVM IR/MLIR pass planning, and hardware-aware native inference lowering from edge to accelerator scale.
---

# Kernel-to-Kernel LLVM Inference Skill

## First-Principles Contract
- **Fusion Over Launch Overhead:** Fuse elementwise, normalization, gating, and MoE dispatch stages where memory-bandwidth bound to minimize global memory round-trips and kernel launch latency.
- **Target-Aware Lowering:** Lower cleanly across targets—from local `aarch64` (`NEON` / `llama.cpp` / `hatchling` Python workers) to x86_64/GPU (`LLVM` / `MLIR` / `PTX` / `AMDGPU`) and cloud AI accelerators (e.g., Google Cloud TPU/GPU infrastructure)—preserving numerical tolerance checks (`atol`/`rtol`) against a reference pass.
- **Reproducible Artifacts:** Record compiler/LLVM version, target triple, optimization flags, and numerical verification status before promoting a fused kernel.

## Workflow
1. Identify candidate adjacent kernels (e.g., router softmax + top-k + expert gating) and verify dataflow dependencies.
2. Propose LLVM/MLIR fusion & lowering steps plus numerical accuracy verification criteria.
3. Run isolated checks via `./scripts/nydo-sandbox.sh` or `./scripts/uv-pipeline.sh` (`UV_LINK_MODE=copy`, `hatchling`) before committing artifacts.
