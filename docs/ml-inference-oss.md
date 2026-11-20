# Open-Source ML Inference Stack (Termux / Linux + `uv`)

## Architecture Principles
- **Local-First & Open Weights:** Prefer open-weight models and open-source runtimes (`llama.cpp` / `Ollama` / local HTTP or CLI inference) with explicit model tags and version pinning.
- **Termux Compatibility:** Keep Python packages pure-Python with `hatchling.build` and `UV_LINK_MODE=copy` so `uv` runs reliably on `aarch64` Android without Rust build failures.
- **Sandboxed Execution:** Run inference experiments and scratch scripts via `./scripts/nydo-sandbox.sh run ...` and manage package builds via `./scripts/uv-pipeline.sh <pkg> <script>`.

## Standard Workflow
1. Ensure `UV_LINK_MODE=copy` is set in the environment.
2. Run or test Python workers through `./scripts/uv-pipeline.sh core-py app`.
3. Keep any API keys or endpoint tokens strictly in `~/.secrets/*.env` (`chmod 600`), never inside `~/ntydo`.
4. Validate outputs deterministically (schema check, exit status, or unit test) before wiring results into downstream workflows.
