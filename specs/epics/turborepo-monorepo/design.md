# turborepo-monorepo — design

## 1. The template

Vercel's "Monorepo Starter: Next.js & Turborepo Template" is Turborepo's
`examples/basic`: a pnpm workspace with two Next.js 16 App Router apps, `web`
(port 3000) and `docs` (port 3001), each one static page that renders the
shared `Button`; `@repo/ui`, three React components shipped as `.tsx` source
through its `exports`; `@repo/eslint-config` (ESLint 10 flat presets over
`@babel/eslint-parser`) and `@repo/typescript-config`. Turborepo runs `build`,
`lint`, `check-types` and `dev` across them, `^build` first. On Vercel it is
two projects with the same repository and a different root directory.

## 2. Two deployables, two components

Each app becomes its own Orun component (`apps/web/component.yaml`,
`apps/docs/component.yaml`, both `cloudflare-workers-assets-turbo`, both
`lane: isolated`), with its own Worker per environment —
`<repo>-web-<env>` and `<repo>-docs-<env>` — and its own smoke. That is the
template's own shape (two Vercel projects), and it is what makes the monorepo
worth having on Orun: `orun plan --changed` maps a change under `apps/docs` to
the docs app alone, and a change under `packages/ui` to both, because each
component's input graph includes the workspace packages it depends on.

The shared packages stay workspace packages, not components: nothing deploys
them, and each app's lane builds what it imports (`turbo run build
--filter=<app>`). `tests/ui` (vitest, the shared components and the product
name) is the one test component, on the `dev` rung.

## 3. The Workers build

Each app: `next build` (Turbopack), then `opennextjs-cloudflare build
--skipBuild` and `populateCache local`, into one `.open-next/worker.js` plus
Static Assets. `next.config.js` adds `output: "standalone"`,
`outputFileTracingRoot` and `turbopack.root` at the workspace root (so
`@repo/ui` resolves from it; Turbopack transpiles its `.tsx` with no
`transpilePackages`), and `images.unoptimized` (every image is an SVG, which
Next serves unoptimised anyway). Both pages are static (`○`), so
`open-next.config.ts` uses the read-only static-assets incremental cache:
nothing to provision. Each Worker is about 973 KiB gzipped (Workers Free: 3
MiB).

Neither page links anything absolute — no sitemap, feed or Open Graph image —
so the build bakes in no origin, and a custom domain is attached to a Worker
without a rebuild.

## 4. The toolchain floor

The template asks for `node >=24`, `pnpm@11.25.0` and TypeScript 7.0.2. The
runners and the composition give Node 22 and pnpm 10.12.1, and nothing in the
template needs more: build, lint, check-types, the tests and the e2e all pass
on Node 22. So `engines.node` is `>=22`, `packageManager` is `pnpm@10.12.1`
and the lockfile is pnpm 10's. TypeScript 7 (the native compiler, shipped as
npm platform binaries) stays for the template's packages: Next 16.3.8
type-checks with it. The baseline's test package lints with typescript-eslint,
which refuses TypeScript 7, so `tooling/eslint` carries its own TypeScript 5.

## 5. The product's name

The template's apps are both titled "Create Next App". The rebrand needs one
seam, and the monorepo's way of sharing is `@repo/ui`, so the name is
`SITE_NAME` in `packages/ui/src/site.ts` (exported as `@repo/ui/site`), read by
both root layouts' `metadata.title`. Its default is the template's own title.

## 6. The repository and the build

portfolio-starter-kit's machinery, renamed, and doubled where it named the one
app: the card's verify URLs, the build document's modules (both apps, the three
packages, `tests/ui`) and probes (four URLs), the redeploy marker's components,
the deployment record (both apps' Workers, each probed), and the tests (the
placement asserts both apps' Workers, builds and smokes in the product's own
plan; the e2e stages, builds, dry-deploys, serves and walks each app in its own
staged lane). `tooling/catalog/gen-component-docs.py` treats a directory with a
`component.yaml` as a component whatever it is called (`docs` was skipped as a
pages folder).

## 7. The alternative rejected

One Worker serving both apps, routed by path or host. It would halve the
lanes, but it is not the template: the apps are independent Next.js builds with
their own `_next` assets and routes, and merging them needs a router Worker in
front, a second build output layout and a shared deploy, so a change to one app
would redeploy the other.
