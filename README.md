# turborepo-monorepo

Vercel's [Monorepo Starter: Next.js & Turborepo](https://github.com/vercel/turborepo/tree/main/examples/basic)
(Turborepo's `basic` example) — two Next.js apps, `web` and `docs`, sharing a
React UI package and their ESLint and TypeScript configs, built by Turborepo —
running on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), one Worker per
app, and packaged as an **Orun baseline**: one command takes a new monorepo
from nothing to both apps live on stage and prod, in its own repository, under
its own name.

The template's code is the code. What the port adds is each app's Workers
build, a test package for the shared UI, and the deploy contract — two
components, each with its own Worker, lane and smoke; what it changes is the
toolchain floor (Node 22 and pnpm 10, where the template asks for Node 24 and
pnpm 11) and one line of the shared ESLint preset (it ignores the Workers
build output). What the baseline adds is everything needed to make a copy of
it somebody else's — built the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) is. See
[`specs/epics/turborepo-monorepo`](specs/epics/turborepo-monorepo/README.md)
for the design, the milestones and the as-built status.

## Instantiating a monorepo

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/turborepo-monorepo
cd turborepo-monorepo
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-notes --run-hooks --resume \
  --set reponame=acme-notes --set productname="Acme Notes" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`turborepo-monorepo` → Build). Two phases — `01-product` (the repository
created, then the whole monorepo in one pull request, both apps deployed to
stage and prod and smoke-tested) and `03-docs` (the live deployment recorded) —
each landing one pull request in the new repository.
**[BOOTSTRAP.md](BOOTSTRAP.md)** is the operator guide;
[docs/phases/](docs/phases/README.md) has a page per phase.

The new repository receives the **monorepo only** — both apps, the shared
packages, the tests, the CI, the tooling, a README and an `AGENTS.md` of its
own and its operating contract — renamed throughout to the product's name,
repository and Cloudflare Workers. None of this repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The monorepo's README, agent page and context pack | `.baseline/product/README.md`, `.baseline/product/AGENTS.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

## What is here (the monorepo)

| Surface | Where |
|---|---|
| The `web` app (its page, layout, fonts, logos) | `apps/web/app`, `apps/web/public` |
| The `docs` app (the same shape, its own page) | `apps/docs/app`, `apps/docs/public` |
| The shared UI — `Button`, `Card`, `Code` | `packages/ui/src` (`@repo/ui`) |
| The product's name, which both apps' tabs read | `packages/ui/src/site.ts` (`SITE_NAME`) |
| The shared ESLint presets and TypeScript configs | `packages/eslint-config`, `packages/typescript-config` |
| Each app's Workers build and deploy contract | `apps/<app>/next.config.js`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |
| Tests | `tests/ui` (vitest: the shared components and the name both apps read) |

## Getting started

```bash
pnpm install
pnpm typecheck        # each package's check-types (next typegen + tsc) and the tests' tsc
pnpm lint
pnpm test
pnpm build            # turbo: next build + opennextjs-cloudflare build → apps/{web,docs}/.open-next
```

```bash
pnpm --filter web dev          # http://localhost:3000
pnpm --filter docs dev         # http://localhost:3001
pnpm --filter web preview      # wrangler dev over the built Worker
```

Neither app reads an environment variable or a secret. Add a component to
`packages/ui/src/` and import it from either app as `@repo/ui/<name>`.

## How it maps to Vercel

| Vercel | Here |
|---|---|
| Two Vercel projects, one per app (`root-directory=apps/web`, `apps/docs`) | Two Cloudflare Workers per environment, `<repo>-web-<env>` and `<repo>-docs-<env>`, each its own Orun component (`apps/web/component.yaml`, `apps/docs/component.yaml`) |
| Next.js hosting (SSG) | `@opennextjs/cloudflare`: each app is one Worker (`.open-next/worker.js`) + Static Assets; the pre-rendered page comes from the static-assets cache |
| Turborepo remote cache on Vercel | Turborepo as the task runner, local cache only (each lane builds its app with `turbo run build --filter=<app>`) |
| `next/image` optimisation | `images.unoptimized` — every image is an SVG, which Next serves unoptimised anyway |
| Deploy on push | Orun deploys both Workers to stage, then prod, on every merge to `main` |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, both apps deployed |

## CI

| Workflow | What it runs | Ships to a monorepo |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a monorepo carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (each app built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, both apps built, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |

The template's code is MIT-licensed by Vercel; each directory it came from
carries the licence (`apps/web/LICENSE.md`, `apps/docs/LICENSE.md`,
`packages/*/LICENSE.md`).
