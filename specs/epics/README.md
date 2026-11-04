# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`turborepo-monorepo/`](./turborepo-monorepo/) | **TR** | In progress (TR1: the site on Workers) | Vercel's Monorepo Starter — Turborepo's basic example, two Next.js apps sharing a UI package — on Cloudflare Workers + Static Assets through OpenNext, one Worker per app, and an Orun baseline that instantiates it (TR2) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
