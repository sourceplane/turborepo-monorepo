# turborepo-monorepo — implementation plan

Three milestones, each one reviewed pull request (TR0 is the repository's
first commit), each green before it merges.

## TR0 — the spec (TR-1)

The repository is born: `intent.yaml` with the placeholder workspace
`ws_CHANGE_ME`, `ci.yml` (byte for byte turso-starter's, which plans nothing
until the workspace is set), the shared TypeScript and ESLint configuration
the tests use, the spec index, this doc set and the task contracts.

## TR1 — the monorepo on Workers (TR-2)

- The template's `apps/web`, `apps/docs`, `packages/ui`,
  `packages/eslint-config` and `packages/typescript-config`, at upstream's
  versions; the root `package.json` and `turbo.json` merged with the
  workspace's own scripts; Node 22 and pnpm 10.12.1 (the lockfile regenerated
  by pnpm 10).
- Each app: `next.config.js` (standalone, the workspace root for the trace and
  Turbopack, images unoptimised), `open-next.config.ts` (the static-assets
  incremental cache), `wrangler.jsonc`, an app `turbo.json` naming the OpenNext
  output, `build` running OpenNext after `next build`, and `component.yaml`
  (its Worker, its lane, its smoke).
- `@repo/ui`'s `site.ts` (`SITE_NAME`), read by both layouts; the shared
  ESLint preset ignores `.open-next/` and `.wrangler/`; the upstream licence in
  each directory the code came from.
- `tests/ui`: the shared components and the product name both apps read.
- The README's "How it maps to Vercel".

## TR2 — a baseline (TR-3)

portfolio-starter-kit's machinery, renamed and doubled to two apps:
`blueprint.yaml`, `repo-blueprint.yaml`, `.baseline/` (identity, the product's
README, its `AGENTS.md` with Turborepo's own agent block, task contracts),
`tooling/rebrand`, `tooling/bootstrap`, `tooling/catalog` (a component named
`docs` found), `hooks/render-deployment-docs.sh` (both apps' Workers probed),
`docs/phases/`, the context pack, `testing/` (the leak and placement gates on
this tree's files; the e2e tier building, dry-deploying and serving each app in
its own staged lane) and `baseline.yml` / `tag.yml`.
