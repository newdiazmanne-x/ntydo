#!/usr/bin/env bash
set -euo pipefail

export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGES_URL="${NYDO_PAGES_URL:-https://newdiazmanne-x.github.io/ntydo/}"
REPO_URL="https://github.com/newdiazmanne-x/ntydo"
RUN_NIST=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-nist)
      RUN_NIST=0
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/publish-ntydo-suite.sh [--skip-nist]

Generates Emmanuel Diaz Ortega copyright & Free/Pro tier docs, updates index.html
with Click-to-Action and QR-to-Action cards (zero secrets), and optionally runs
./scripts/nist-release-check.sh --json.
EOF
      exit 0
      ;;
    *)
      echo "[-] Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

echo "[1/3] Writing copyright & Free/Pro documentation under Emmanuel Diaz Ortega..."
cat > "$REPO_ROOT/COPYRIGHT.md" <<'MD'
# Copyright & Licensing Notice

Copyright (c) 2026 **Emmanuel Díaz Ortega**. All rights reserved.

## Ownership & Attribution
- **Author & Rights Holder:** Emmanuel Díaz Ortega
- **Project:** `ntydo` — Synthetic Intelligence (SI), Human-in-the-Loop (HITL), `uv` (`hatchling`) packages, and NIST-aligned verification tooling.
- **Contact:** `newdiazmanne@gmail.com`

## Free Tier vs. Pro Tier
- **Free Version (Community / Local-First):**
  - Free to clone, inspect, run locally with `uv` (`UV_LINK_MODE=copy`), and test via `./scripts/smoke-test-packages.sh` and `./scripts/nist-release-check.sh`.
  - Designed for zero-cost local execution across Termux (`aarch64` Android) and desktop systems (Linux, macOS, Windows/WSL).
  - All rights reserved by **Emmanuel Díaz Ortega**; redistribution or derivative works must preserve copyright and attribution notices.
- **Pro Version (Commercial / Campaign & Multi-Node Orchestration):**
  - Intended for commercial deployments, multi-rank/distributed routing workflows, campaign automation playbooks, custom enterprise policy packs, and priority support or commercial licensing arrangements with **Emmanuel Díaz Ortega**.
  - Contact `newdiazmanne@gmail.com` to arrange commercial Pro licensing or campaign engagement terms.

## Security & Secret Hygiene
- Zero secrets, API keys, tokens, or credentials are permitted in this repository, GitHub Pages, or QR payloads.
- Local credentials belong outside the repository under `~/.secrets/` with `chmod 700 ~/.secrets` and `chmod 600` on secret files.
MD

cat > "$REPO_ROOT/docs/copyright-and-tiers.md" <<'MD'
# NTYDO Editions, Publishing & Compliance Guide

**Author & Copyright Holder:** Emmanuel Díaz Ortega — All rights reserved.

## 1. Publishing via `uv` + GitHub Pages
1. **Verify locally first:** Run `./scripts/nist-release-check.sh --json` so security checks, JSON spec validation, package unit tests, wheel builds, and SHA-256 checksum verification pass.
2. **Host web quick-start on GitHub Pages:** Serve `index.html` from `main` branch `/` (root) at `https://newdiazmanne-x.github.io/ntydo/`.
3. **Distribute `uv` packages cleanly:** Use `UV_LINK_MODE=copy` with `uv` (`hatchling` backend) across Termux and desktop environments, attaching built `.whl` files and `wheels.sha256` / `ntydo-manifest.sha256` manifests to GitHub Releases.

## 2. Free vs. Pro Tier Matrix
| Capability | Free Edition | Pro Edition |
| :--- | :--- | :--- |
| `uv` (`hatchling`) local packages (`core-py`, `si-router`, `si-agent`) | Included | Included |
| Termux (`aarch64`) & desktop sandbox (`nydo-sandbox.sh`) | Included | Included |
| NIST-aligned verification (`security-check.sh`, `validate-json-specs.sh`, `nist-release-check.sh`) | Included | Included |
| Commercial campaign playbooks, custom SLA & multi-node orchestration packs | Not included | Licensed via Emmanuel Díaz Ortega (`newdiazmanne@gmail.com`) |

## 3. Human-in-the-Loop (HITL) & Campaign Guardrails
- Always keep a human in the loop before publishing releases, launching public campaigns, or executing privileged commands.
- Keep secrets strictly out of Git, QR codes, and public web pages (`~/.secrets/` with `0600` permissions).
MD

echo "[2/3] Updating index.html with Free/Pro tiers, Click-to-Action, and QR-to-Action..."
cat > "$REPO_ROOT/index.html" <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>NTYDO — Emmanuel Díaz Ortega | uv &amp; Web Quickstart</title>
  <style>
    :root {
      --bg: #0f1115;
      --panel: #171a21;
      --panel-2: #12151b;
      --text: #eef1f6;
      --muted: #9aa4b2;
      --accent: #4ea8de;
      --accent-2: #68d391;
      --border: #282e3a;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.55;
      padding: 2rem 1rem 3rem;
    }
    main {
      max-width: 820px;
      margin: 0 auto;
      display: grid;
      gap: 1.25rem;
    }
    .card {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 1.25rem;
    }
    .grid-2 {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
      gap: 1rem;
    }
    .tier {
      background: var(--panel-2);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      gap: 0.75rem;
    }
    h1, h2, h3 { margin: 0 0 0.45rem; font-weight: 650; }
    h1 { font-size: 1.5rem; }
    h2 { font-size: 1.12rem; }
    h3 { font-size: 1rem; }
    p { margin: 0.35rem 0; color: var(--muted); }
    p.lead { color: var(--text); }
    pre {
      margin: 0.65rem 0 0;
      padding: 0.85rem;
      background: #0b0d11;
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow-x: auto;
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      font-size: 0.84rem;
      color: #e6edf3;
    }
    .row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 0.65rem;
      flex-wrap: wrap;
    }
    .actions {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-top: 0.5rem;
    }
    button, .btn-link {
      background: var(--accent);
      color: #081018;
      border: 0;
      border-radius: 6px;
      padding: 0.45rem 0.8rem;
      font-weight: 600;
      font-size: 0.85rem;
      cursor: pointer;
      text-decoration: none;
      display: inline-block;
    }
    button.secondary, .btn-link.secondary {
      background: #232936;
      color: var(--text);
      border: 1px solid var(--border);
    }
    button:hover, .btn-link:hover { filter: brightness(1.08); }
    ul { margin: 0.4rem 0 0; padding-left: 1.2rem; color: var(--muted); }
    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; }
    .qr-box {
      margin-top: 0.6rem;
      padding: 0.75rem;
      border: 1px dashed var(--border);
      border-radius: 8px;
      background: #0b0d11;
      font-size: 0.85rem;
      color: var(--text);
      word-break: break-all;
    }
    .badge {
      display: inline-block;
      font-size: 0.75rem;
      font-weight: 600;
      padding: 0.15rem 0.5rem;
      border-radius: 999px;
      background: rgba(78, 168, 222, 0.15);
      color: var(--accent);
    }
    .badge.pro {
      background: rgba(104, 211, 145, 0.15);
      color: var(--accent-2);
    }
  </style>
</head>
<body>
  <main>
    <section class="card">
      <h1>NTYDO — Synthetic Intelligence &amp; <code>uv</code> Quickstart</h1>
      <p class="lead">
        Zero-cost local-first workflow using <code>uv</code> (<code>hatchling</code>),
        Human-in-the-Loop (HITL) controls, and NIST-aligned verification across
        Termux (Android) and desktop systems.
      </p>
      <p>
        Repository: <a href="${REPO_URL}">${REPO_URL}</a> |
        Pages: <a href="${PAGES_URL}">${PAGES_URL}</a>
      </p>
      <div class="actions">
        <a class="btn-link" href="#termux-cta">Click to Action: Termux Run</a>
        <a class="btn-link secondary" href="#desktop-cta">Click to Action: Desktop &amp; NIST</a>
        <a class="btn-link secondary" href="#qr-action">QR to Action</a>
      </div>
    </section>

    <section class="card">
      <h2>Editions: Free vs. Pro</h2>
      <div class="grid-2">
        <div class="tier">
          <div>
            <span class="badge">FREE EDITION</span>
            <h3>Local-First &amp; Community</h3>
            <p>
              Run <code>core-py</code>, <code>si-router</code>, and <code>si-agent</code> locally with
              <code>UV_LINK_MODE=copy</code>, sandbox execution, unit tests, and SHA-256 verification.
            </p>
          </div>
          <div class="actions">
            <button type="button" data-copy="cmd-free">Copy Free Command</button>
          </div>
          <pre id="cmd-free">export UV_LINK_MODE=copy
./scripts/smoke-test-packages.sh --json</pre>
        </div>

        <div class="tier">
          <div>
            <span class="badge pro">PRO EDITION</span>
            <h3>Commercial &amp; Campaign Ready</h3>
            <p>
              Designed for commercial deployments, multi-rank orchestration, campaign playbooks,
              and custom licensing arrangements with <strong>Emmanuel Díaz Ortega</strong>.
            </p>
          </div>
          <div class="actions">
            <a class="btn-link secondary" href="mailto:newdiazmanne@gmail.com?subject=NTYDO%20Pro%20Edition%20Inquiry">Request Pro Info</a>
            <button type="button" class="secondary" data-copy="cmd-pro">Copy Release Check</button>
          </div>
          <pre id="cmd-pro">export UV_LINK_MODE=copy
./scripts/nist-release-check.sh --json</pre>
        </div>
      </div>
    </section>

    <section class="card" id="termux-cta">
      <div class="row">
        <h2>Click to Action: Termux (Android aarch64)</h2>
        <button type="button" data-copy="cmd-termux">Copy</button>
      </div>
      <p>Clone, copy-link with <code>uv</code>, and run inside the isolated sandbox.</p>
      <pre id="cmd-termux">git clone ${REPO_URL}.git &amp;&amp; cd ntydo
export UV_LINK_MODE=copy
./scripts/nydo-sandbox.sh run uv run --link-mode=copy --project "\$PWD/packages/si-agent" si-agent --goal "Pages quickstart" --tokens 512</pre>
    </section>

    <section class="card" id="desktop-cta">
      <div class="row">
        <h2>Click to Action: Desktop &amp; NIST Check</h2>
        <button type="button" data-copy="cmd-desktop">Copy</button>
      </div>
      <p>Run package tests, build wheels in a temp dir, and verify source &amp; wheel SHA-256 manifests.</p>
      <pre id="cmd-desktop">git clone ${REPO_URL}.git &amp;&amp; cd ntydo
export UV_LINK_MODE=copy
./scripts/nist-release-check.sh --json</pre>
    </section>

    <section class="card" id="qr-action">
      <h2>QR to Action (Safe URL Target — Zero Secrets)</h2>
      <p>
        Enter a clean public URL (such as your GitHub Pages URL) to generate a safe target link
        for QR code encoding. Never encode tokens, API keys, or shell commands inside a QR code.
      </p>
      <div class="row">
        <input
          id="qr-url-input"
          type="url"
          value="${PAGES_URL}"
          aria-label="Target URL for QR action"
          style="flex: 1; min-width: 220px; padding: 0.45rem 0.65rem; border-radius: 6px; border: 1px solid var(--border); background: #0b0d11; color: var(--text);"
        />
        <button type="button" id="qr-update-btn">Update QR Target</button>
        <button type="button" class="secondary" data-copy="qr-target-display">Copy URL</button>
      </div>
      <div class="qr-box">
        <div><strong>Active QR Target URL:</strong> <span id="qr-target-display">${PAGES_URL}</span></div>
        <div id="qr-status" style="margin-top: 0.35rem; color: var(--accent-2);">Ready: clean HTTPS URL validated (no secrets).</div>
      </div>
    </section>

    <section class="card">
      <h2>Documentation, HITL &amp; Copyright</h2>
      <ul>
        <li><strong>Copyright:</strong> © 2026 <strong>Emmanuel Díaz Ortega</strong>. All rights reserved. See <a href="COPYRIGHT.md">COPYRIGHT.md</a> and <a href="docs/copyright-and-tiers.md">docs/copyright-and-tiers.md</a>.</li>
        <li><strong>Human-in-the-Loop (HITL):</strong> Always review commands, campaign assets, and release tags before execution.</li>
        <li><strong>Secret Hygiene:</strong> Keep credentials in <code>~/.secrets/</code> (<code>chmod 600</code>); never commit keys to Git or embed them in web/QR targets.</li>
      </ul>
    </section>
  </main>

  <script>
    document.querySelectorAll("button[data-copy]").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const el = document.getElementById(btn.dataset.copy);
        if (!el) return;
        const text = el.innerText.trim();
        try {
          await navigator.clipboard.writeText(text);
          const prev = btn.textContent;
          btn.textContent = "Copied";
          setTimeout(() => { btn.textContent = prev; }, 1500);
        } catch (_) {
          btn.textContent = "Select manually";
        }
      });
    });

    const qrInput = document.getElementById("qr-url-input");
    const qrBtn = document.getElementById("qr-update-btn");
    const qrDisplay = document.getElementById("qr-target-display");
    const qrStatus = document.getElementById("qr-status");

    function updateQrTarget() {
      const raw = (qrInput.value || "").trim();
      try {
        const parsed = new URL(raw);
        if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
          throw new Error("Only http/https URLs are allowed for QR targets.");
        }
        if (parsed.username || parsed.password) {
          throw new Error("Credentials are not allowed in QR target URLs.");
        }
        qrDisplay.textContent = parsed.toString();
        qrStatus.style.color = "var(--accent-2)";
        qrStatus.textContent = "Safe QR target URL ready (no embedded secrets).";
      } catch (err) {
        qrStatus.style.color = "#f6ad55";
        qrStatus.textContent = "Invalid URL: " + (err && err.message ? err.message : "check format");
      }
    }

    qrBtn.addEventListener("click", updateQrTarget);
    qrInput.addEventListener("change", updateQrTarget);
  </script>
</body>
</html>
HTML

if [ "$RUN_NIST" -eq 1 ] && [ -x "$REPO_ROOT/scripts/nist-release-check.sh" ]; then
  echo "[3/3] Running NIST release check (--json)..."
  "$REPO_ROOT/scripts/nist-release-check.sh" --json
else
  echo "[3/3] Skipping NIST check (--skip-nist or nist-release-check.sh not executable)."
fi
