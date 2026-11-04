# turborepo-monorepo — risks and open questions

| ID | Risk | State | Notes |
|---|---|---|---|
| TR-A | `baseline-v1` is not yet proven live | OPEN | Proven offline in Baseline CI: the offline bootstrap with the blueprint's own hooks, the product's own plan (four deploy lanes), each app's stage lane in its own staged job tree, each Worker served by `wrangler dev` and smoke-tested with its component's own command. A console bootstrap closes it, and measures four lanes side by side against the card's 6-minute estimate |
| TR-B | The toolchain floor: Node 22 and pnpm 10, where the template asks for Node 24 and pnpm 11 | WATCH | Nothing in the template needs either today. A template bump that does (a Node 24 API, a pnpm 11 lockfile feature) fails the e2e tier, which installs with the shipped lockfile and builds both apps |
| TR-C | The shared ESLint preset ignores `.open-next/` and `.wrangler/` | ACCEPTED | Without it ESLint lints the Worker bundle OpenNext writes into each app (7.5k warnings under `--max-warnings 0`); the template's own source is linted unchanged |
| TR-D | No remote Turborepo cache | ACCEPTED | Each lane builds its app and `@repo/ui` from scratch; the build is under a minute, and a remote cache would be another credential |
| TR-E | TypeScript 7 for the template, TypeScript 5 for the test tooling | ACCEPTED | typescript-eslint refuses TypeScript 7; the test package's linter carries its own TypeScript 5, and the template's packages type-check with 7 as upstream does |
