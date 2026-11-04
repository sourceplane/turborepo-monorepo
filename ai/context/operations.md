# turborepo-monorepo — operating contract (for humans and agents)

This is the standing guide to how this monorepo is deployed and operated.
Instance facts (live URLs, workspace, the secrets it uses) live in
[deployment.md](deployment.md), rendered from probed reality by the
bootstrap's `03-docs` phase; this file is the contract that stays true
between deployments. It is written to give an agent with repository read
access enough context to reason about and operate the monorepo without any
other source.

## What this system is

A Turborepo monorepo on Cloudflare alone, expressed as an Orun
component-native desired-state repo.

- **`apps/web`** and **`apps/docs`** — the two apps: Next.js, each built by
  `@opennextjs/cloudflare` into its own Worker plus Static Assets. Each page is
  pre-rendered at build time and served from the assets cache. There is no
  database and no runtime secret.
- **`packages/ui`** — the React components both apps import (`@repo/ui`), and
  the product's name (`SITE_NAME`), which both apps' tabs read.
- **`packages/eslint-config`**, **`packages/typescript-config`** — the
  presets every package extends.
- **`tests/ui`** — the shared components' and the shared name's tests
  (vitest), verified on the `dev` rung.
- **`tooling/*`** — the tests' TypeScript and ESLint configuration, and the
  deploy-time wrangler renderer for workers that take wiring.

Environments: **`stage`** and **`prod`** are deployed; **`dev` is
verify-only by design** — lanes build and test, nothing deploys.

## Identity and tenancy

Every remote operation runs against ONE Orun workspace, declared in
`intent.yaml` under `execution.state.workspace` — committed, enforced, and
what CI uses. Do not remove it; headless credentials depend on it. If it
reads `ws_SET_ME`, the bootstrap had no workspace to write: set the real one
before anything else.

## How deployment works

1. Merge (or push) to `main`.
2. CI (`.github/workflows/ci.yml`) runs `orun plan --changed` — only
   components whose files changed are planned: a change under `apps/docs`
   plans the docs app, one under `packages/ui` plans both — then runs each
   planned lane with `orun run --remote-state`, authenticated by GitHub OIDC
   (the exchange resolves this repository's linked workspace server-side).
3. Each planned app builds once per environment (`turbo run build
   --filter=<app>`, which builds the packages it depends on first), then
   `wrangler deploy` ships `turborepo-monorepo-<app>-<env>` and a smoke test
   fetches `/` and a logo from it.
4. `prod` deploys after `stage` has converged on the same commit
   (`environments.prod.promotion` in intent.yaml).
5. **The convergence run is the deployment.** A green run means every
   planned lane applied. Failed lanes are retried with
   `gh run rerun --failed`, which resumes the same execution.

Caveats that matter:

- A push that touches no component files plans zero lanes — that run is
  green and deployed nothing. Never treat "latest run green" as "converged";
  probe the URLs instead.
- A change to `intent.yaml`'s `environments` maps to no component and
  redeploys nothing on its own. Land it with a change under an app.

## Secrets model

- **Brokered provider secrets**: `CLOUDFLARE_API_TOKEN` (Workers deploy
  scope) and `CLOUDFLARE_ACCOUNT_ID` — pointers minted per run from the
  workspace's Cloudflare connection, used by both apps' lanes. No long-lived
  values at rest; nothing to rotate by hand.
- Inspect by NAME only: `orun secrets list --org <ws> --project` and
  `--env stage|prod`. No tooling in this repository prints a secret value,
  and no document in `ai/context/` may contain one.
- Neither app needs a runtime secret.

## Verifying the system

```bash
# both apps on each environment (also recorded, probed, in deployment.md)
for app in web docs; do for env in stage prod; do
  curl -s -o /dev/null -w "$app $env %{http_code}\n" "https://turborepo-monorepo-$app-$env.your-workers-subdomain.workers.dev/"
done; done

# workspace readiness (integrations + repository link)
orun integrations list --org <ws> --json && orun cloud check --org <ws>
```

## Common operations

| task | how |
|---|---|
| change one app | edit under `apps/<app>`, merge — only that app deploys |
| change what both apps share | edit under `packages/ui` (or the config packages), merge — both apps deploy |
| deploy a change | merge to `main`; watch the run; failed lanes → `gh run rerun --failed` |
| deploy by hand | Orunbase's Deploy button, or `gh workflow run ci.yml --ref main -f environment=<env> [-f component=<a,b>]` — the named components (blank: every one) run in that environment as a merge runs them; started off `main` it is refused |
| redeploy without a change | edit the last line of `apps/<app>/component.yaml` (`# orun: redeploy <reason> <stamp>`) and merge — it is a deploy trigger, nothing reads it |
| serve a custom domain | attach it to the app's Worker in Cloudflare, and replace the placeholder `turborepo-monorepo.example.com` in `intent.yaml`'s `BASE_DOMAIN` (dev, stage and prod) with it (README, "Custom domain") |
| add a runtime secret | `orun secrets set <KEY> --org <ws> --env <env>` |
| headless credentials | `ORUN_TOKEN` (workspace-scoped) + `GITHUB_TOKEN` |

The deployment record is the bootstrap's `03-docs` phase. Re-running it (the
Orun console's Retry on that phase, or `orun new … --phase 03-docs`)
re-probes the URLs and re-renders [deployment.md](deployment.md); it is
idempotent.

## Evolution

Structural changes (a third app, an API, a data store) follow the same
contract that deployed the two apps: add a component under `apps/`, `infra/`
or `packages/` with a `component.yaml`, land it as a pull request, and the
convergence run applies it.
