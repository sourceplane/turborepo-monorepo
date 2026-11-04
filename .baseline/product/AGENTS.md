# turborepo-monorepo — for coding agents

Start here before you change this monorepo. This page is short on purpose: the
pages it points at hold the detail, and they are kept true.

## What this is

A Turborepo monorepo: two Next.js apps, `web` and `docs`, each built by
`@opennextjs/cloudflare` into its own Cloudflare Worker with Static Assets,
sharing `@repo/ui` (React components) and the `@repo/eslint-config` and
`@repo/typescript-config` packages. Orun deploys both to `stage` and `prod` on
every merge to `main`; `dev` only verifies. Two deployable components
(`apps/web`, `apps/docs`) and the tests for the shared UI (`tests/ui`); no
database and no runtime secret.

## Read first, in this order

1. [README.md](README.md) — what is where, how to run it, the live URLs.
2. [ai/context/operations.md](ai/context/operations.md) — the operating
   contract: how a merge deploys, the secrets model, common operations.
3. [ai/context/deployment.md](ai/context/deployment.md) — what is live, as
   last probed.
4. [apps/web/docs/overview.md](apps/web/docs/overview.md) and
   [apps/docs/docs/overview.md](apps/docs/docs/overview.md) — the two
   components, each with `architecture.md` and `runbook.md` beside it.
5. [packages/ui/src/site.ts](packages/ui/src/site.ts) — the product's name,
   which both apps' tabs read.

## Working on it

```bash
pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build
pnpm --filter web dev          # http://localhost:3000
pnpm --filter docs dev         # http://localhost:3001
```

Each app's page is `apps/<app>/app/page.tsx`. A component both apps share is
`packages/ui/src/<name>.tsx`, imported as `@repo/ui/<name>`.

## How a change lands

- The repository is desired state. `intent.yaml` declares the environments
  and the workspace; `apps/web/component.yaml` and `apps/docs/component.yaml`
  declare how each app is built, deployed and smoke-tested.
- `orun plan --changed` shows which components and environments a change
  touches: a change to one app deploys that app, a change to a shared package
  deploys both. CI runs the same plan on every pull request.
- One task, one pull request to `main`. On the pull request `ci.yml`'s
  verify lanes run (each app built and dry-deployed per environment); they do
  not lint or run the tests, so run `pnpm typecheck && pnpm lint && pnpm test`
  before you push. The merge's `ci.yml` run deploys stage and prod and
  smoke-tests each. That run is the deployment: retry a red lane with
  `gh run rerun --failed`.
- With Orun's work plane: `orun task create --brief "…"` issues a task key,
  `orun pr open --task <KEY>` opens its pull request on `orun/<KEY>-<slug>`,
  and `orun pr land` merges it once its checks pass. Leave the `BASE` prefix
  to the bootstrap: CI checks `orun/BASE-…` branches with `plan` alone.
- A change to `intent.yaml` alone deploys nothing; carry it with a change
  under `apps/web` or `apps/docs`.

## Do not touch

- `execution.state.workspace` in `intent.yaml`: every remote operation, and
  CI's OIDC exchange, claims that workspace.
- `ai/context/deployment.md`, and the README between `<!-- 03-docs:begin -->`
  and `<!-- 03-docs:end -->`: rendered from probed URLs, never by hand.
- `.rebrand/values.json`: the identity the monorepo was created with, which
  the deployment record is rendered from.
- Secrets. `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` are brokered
  per run from the workspace's Cloudflare connection; never put a value in
  the repository or in GitHub. List them by name (operations.md).
- `ci.yml` stays the only workflow that runs on a push to `main`.
- `pnpm-lock.yaml` changes through `pnpm install`, never by hand: CI
  installs with `--frozen-lockfile`.

## Turborepo's own guidance

The block below is Turborepo's: `turbo` keeps it in this file when it detects
a coding agent, so leave it as it is.

<!-- BEGIN:turborepo-agent-rules -->

# This is NOT the Turborepo you know

Turborepo configuration, task behavior, and CLI commands can vary between installed versions and may differ from your training data. Resolve the `turbo` package from this file's directory or relevant workspace; in monorepos, it may not be visible from the repository root. For example, run `node -p "require.resolve('turbo/package.json')"` from a workspace that depends on `turbo`.

Read `docs/README.md` inside that installed package first, then read the relevant pages from its `docs/` directory before changing Turborepo configuration or commands. Heed deprecation notices. These bundled docs match the installed package version and are available without network access.

This block is written and re-added by `turbo` before repository-scoped commands when an AI agent is detected. In the Turborepo source repository, its template is defined in `crates/turborepo-cli/src/cli/agent_guidance.rs`. Removing the managed block while updates are enabled means a later qualifying invocation will add it again. Set `"agentGuidance": true` in the root `turbo.json` or `turbo.jsonc` to opt in; this does not remove an existing block. Keep the block committed with your work to avoid an uncommitted change on the next agent invocation.
<!-- END:turborepo-agent-rules -->
