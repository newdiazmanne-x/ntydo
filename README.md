# NTYDO — Independent Research

**Singularity Resources Computing**

NTYDO develops adaptive post-silicon infrastructure, autonomous machine-native
systems, and experimental compute architectures designed for next-generation
intelligence environments.

Live site: `index.html` — self-contained, no build step, three.js loaded from
a CDN `<script>` tag. Deploys straight from GitHub Pages.

## Focus areas

- Autonomous Compute Systems
- Native AI Infrastructure
- Distributed Resource Orchestration
- Experimental Physics-Inspired Computing
- Digital Twins & Computational Simulation
- Advanced Serialization Engines
- Chip-to-Chip Communication
- Open Research Tooling

## Structure

```
ntydo/
├── index.html        # site root — served by GitHub Pages
├── specimens/         # (optional) one folder per standalone three.js demo
└── README.md
```

## Local preview

Any static server works, e.g.:

```
python3 -m http.server 8000
```

then open `http://localhost:8000`.

## Deploy

Push to `main`, then in the repo: **Settings → Pages → Source: Deploy from a
branch → main / (root)**. The site publishes at
`https://<username>.github.io/ntydo`.

---

© 2026 Emmanuel Díaz Ortega. All Rights Reserved.
