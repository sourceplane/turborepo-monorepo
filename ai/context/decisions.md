# turborepo-monorepo — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | Each app is its own Worker and its own component (`web`, `docs`), deployed by `cloudflare-workers-assets-turbo` | The template deploys as two Vercel projects; one component per deployable keeps a change to one app from redeploying the other, and `orun plan --changed` maps a change to `packages/ui` to both | design.md §2 |
| 2 | OpenNext on Workers + Static Assets, the static-assets incremental cache + `populateCache` | Both pages are static (`○`); the portfolio-starter-kit build shape | design.md §3 |
| 3 | The shared packages stay workspace packages, not components | Nothing deploys them; each app's build compiles what it imports, and Turborepo orders `^build` | design.md §2 |
| 4 | Node 22 and pnpm 10.12.1, where the template asks for `node >=24` and pnpm 11.25 | The runners and the composition give Node 22 and pnpm 10; nothing in the template needs Node 24 (build, lint, check-types and the e2e pass on 22). The lockfile is pnpm 10's | IMPLEMENTATION-STATUS |
| 5 | TypeScript 7.0.2 kept for the template's packages; the baseline's test tooling stays on TypeScript 5 | Next 16.3.8 type-checks with TypeScript 7; typescript-eslint (the test package's linter) refuses TypeScript 7, so `tooling/eslint` carries its own TypeScript 5 | IMPLEMENTATION-STATUS |
| 6 | The product's name is one literal in `@repo/ui` (`SITE_NAME`), read by both layouts' `metadata.title`; its default is the template's own title, "Create Next App" | The rebrand needs one seam, and the two apps share everything else through `@repo/ui` | IMPLEMENTATION-STATUS |
| 7 | No build origin | Neither app links anything absolute (no sitemap, feed or Open Graph image), so a custom domain is attached without a rebuild | design.md §3 |
| 8 | One landing (`01-product`) then the record (`03-docs`); the bootstrap's landings checked here (`checks: local`) | portfolio-starter-kit's shape (cirrus-baseline since baseline-v22) | `repo-blueprint.yaml` |
| 9 | stack-tectonic 0.19.0 | Turbopack refuses 0.20.0's lane-shared install (portfolio-starter-kit's PK-J) | `intent.yaml` |
| 10 | The workers.dev subdomain is read from the Cloudflare connection, and the console asks for no domain | portfolio-starter-kit's PK-8 and PK-9 | `blueprint.yaml` |
