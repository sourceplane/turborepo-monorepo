# turborepo-monorepo

Vercel's [Monorepo Starter: Next.js & Turborepo](https://github.com/vercel/turborepo/tree/main/examples/basic)
(Turborepo's `basic` example) — two Next.js apps, `web` and `docs`, sharing a
React UI package and their ESLint and TypeScript configs, built by Turborepo —
running on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), one Worker per
app, deployed by
[Orun](https://github.com/sourceplane/orun) to stage and prod on every merge.
Packaging it as an Orun baseline is the next milestone (TR2).

The template's code is the code. What the port adds is each app's Workers
build, a test package for the shared UI, and the deploy contract — two
components, each with its own Worker, lane and smoke; what it changes is the
toolchain floor (Node 22 and pnpm 10, where the template asks for Node 24 and
pnpm 11) and one line of the shared ESLint preset (it ignores the Workers
build output). See
[`specs/epics/turborepo-monorepo`](specs/epics/turborepo-monorepo/README.md)
for the design, the milestones and the as-built status.

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

The template's code is MIT-licensed by Vercel; each directory it came from
carries the licence (`apps/web/LICENSE.md`, `apps/docs/LICENSE.md`,
`packages/*/LICENSE.md`).
