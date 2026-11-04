# turborepo-monorepo — Vercel's Monorepo Starter on Cloudflare Workers

**Turborepo's basic example — two Next.js apps, `web` and `docs`, sharing a
React UI package and their ESLint and TypeScript configs — built by Turborepo
and OpenNext into two Cloudflare Workers, one per app, deployed by Orun to stage
and prod on every merge, and the baseline that makes a copy of it somebody
else's in one landing.**

| | |
|---|---|
| Status | In progress — TR0 on main |
| Upstream | [vercel/turborepo › examples/basic](https://github.com/vercel/turborepo/tree/main/examples/basic), at `d95ea89` (2026-11-04), MIT |
| Reference | [portfolio-starter-kit](https://github.com/sourceplane/portfolio-starter-kit) — the same scaffolding, tests and bootstrap, doubled to two apps |
| Key | `TR` |

## Read in this order

1. [design.md](design.md) — the template, its two deployables, the Workers
   build, the toolchain floor, the repository and the build, and the
   alternative rejected.
2. [implementation-plan.md](implementation-plan.md) — the milestones and what
   each one lands.
3. [risks-and-open-questions.md](risks-and-open-questions.md) — what is not
   proven, and what was accepted.
4. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md) — what shipped, and
   every departure from the upstream template.

## Milestones

| Milestone | What it lands | Task |
|---|---|---|
| TR0 — the spec | the repository, its intent, CI, tooling and spec index; this doc set | TR-1 |
| TR1 — the monorepo on Workers | the template's two apps and three packages; each app's OpenNext build and Worker; the two deploy contracts; `tests/ui` | TR-2 |
| TR2 — a baseline | the console card, the build document, the context pack and the baseline's tests | TR-3 |
