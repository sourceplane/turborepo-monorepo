# turborepo-monorepo

A Turborepo monorepo — two Next.js apps, `web` and `docs`, sharing a React UI
package (`@repo/ui`) and their ESLint and TypeScript configs — on **Cloudflare
Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), one Worker per
app.

Working on it with a coding agent? [AGENTS.md](AGENTS.md) says what to read
first, how a change lands and what not to touch.

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the apps use into
[ai/context/deployment.md](ai/context/deployment.md); how they deploy and how
to operate them is in [ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The `web` app (its page, layout, fonts, logos) | `apps/web/app`, `apps/web/public` |
| The `docs` app (the same shape, its own page) | `apps/docs/app`, `apps/docs/public` |
| The shared UI — `Button`, `Card`, `Code` | `packages/ui/src` (`@repo/ui`) |
| The product's name, which both apps' tabs read | `packages/ui/src/site.ts` (`SITE_NAME`) |
| The shared ESLint presets and TypeScript configs | `packages/eslint-config`, `packages/typescript-config` |
| Each app's Workers build and deploy contract | `apps/<app>/next.config.js`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |
| Tests | `tests/ui` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck
pnpm lint
pnpm test
pnpm build            # turbo: next build + opennextjs-cloudflare build → apps/{web,docs}/.open-next
```

```bash
pnpm --filter web dev          # http://localhost:3000
pnpm --filter docs dev         # http://localhost:3001
pnpm --filter web preview      # wrangler dev over the built Worker
```

Make the apps yours in `apps/web/app/page.tsx` and `apps/docs/app/page.tsx`.
A component both apps use goes in `packages/ui/src/<name>.tsx` and is imported
as `@repo/ui/<name>`; Turborepo rebuilds every app that depends on it. Neither
app reads an environment variable or a secret.

## How it deploys

Merges to `main` converge through [Orun](https://github.com/sourceplane/orun):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. Each app is its own component with its
own lane: it deploys to `stage`, then to `prod` once stage has converged on the
same commit; `dev` only verifies. The Workers are
`turborepo-monorepo-web-<env>` and `turborepo-monorepo-docs-<env>` on your
account's workers.dev subdomain, and every deploy is smoke-tested over HTTP. A
change under `apps/docs` deploys only the docs app; a change under
`packages/ui` deploys both. A pull request runs the same pipeline's verify
lanes: each app built and dry-deployed for each environment, with nothing
deployed. They do not lint or run the tests, so run `pnpm typecheck`,
`pnpm lint` and `pnpm test` before you push. (A push to `main` builds, deploys
and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The Cloudflare
token and account id are brokered per run from the workspace's Cloudflare
connection; nothing provider-shaped is stored in the repository or in GitHub.

**Deploy by hand.** Orunbase's **Deploy** button on a component, or **Run
workflow** on the CI workflow in GitHub's Actions tab (on `main`), runs
`ci.yml` for the environment and components you pick, and each one deploys
exactly as a merge would deploy it. Leave the component blank to redeploy
every component in that environment, with nothing changed: after rotating a
secret, say. A component with nothing to run in that environment (a test
suite in `prod`) is left out with a notice.

## Custom domain

Both apps answer on workers.dev from their first deploy. To serve one on your
own domain, add the domain to the Cloudflare account the apps deploy into and
attach it to that app's Worker (dashboard → Workers & Pages →
`turborepo-monorepo-web-prod` or `turborepo-monorepo-docs-prod` → Settings →
Domains & Routes → Add → Custom domain). Do the same for stage with a
subdomain if you want one. Neither app links anything absolute, so nothing is
rebuilt.

The monorepo was born with the reserved placeholder
`turborepo-monorepo.example.com` where its domain goes: `BASE_DOMAIN` under
each environment (dev, stage and prod) in `intent.yaml`. Replace it with your
domain when you attach one.
