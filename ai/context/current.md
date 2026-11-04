# turborepo-monorepo — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a monorepo built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's Monorepo Starter (Turborepo's `basic` example) — two Next.js apps,
`web` and `docs`, sharing `@repo/ui` and their ESLint and TypeScript configs —
on Cloudflare Workers + Static Assets (`@opennextjs/cloudflare`), one Worker per
app, packaged as an Orun baseline: `orun new --blueprint repo-blueprint.yaml`
builds a new monorepo in its own repository and takes both apps to live on
stage and prod in one landing (`01-product`), then records what went live
(`03-docs`). Two deployable components, no infra.

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` — TR0–TR2 ([#1](https://github.com/sourceplane/turborepo-monorepo/pull/1)–[#3](https://github.com/sourceplane/turborepo-monorepo/pull/3)): the spec, both apps on Workers, the baseline |
| Proven live | Not yet (risk TR-A): every tier passes offline, including both apps built in their staged lanes and served |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/turborepo-monorepo/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/turborepo-monorepo/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/turborepo-monorepo/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What each component is | `apps/web/docs/`, `apps/docs/docs/`, `tests/ui/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |
| What a monorepo's agent reads first | `.baseline/product/AGENTS.md` (ships as the monorepo's `AGENTS.md`) |

## Next

1. Bootstrap one monorepo from `baseline-v1` against a workspace with Cloudflare
   connected: both apps' stage and prod Workers live, four lanes side by side,
   and the timings recorded against the card's 6-minute estimate (closes TR-A).
