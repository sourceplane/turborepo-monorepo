# turborepo-monorepo — open risks

What is not yet proven or not yet decided. The full write-up of every risk,
including the accepted ones, is
`specs/epics/turborepo-monorepo/risks-and-open-questions.md`; this page lists
only what is still live, so it should be short.

| ID | Risk | State | What closes it |
|---|---|---|---|
| TR-A | No live bootstrap yet: four deploy lanes (two apps × stage and prod) side by side on real runners | OPEN | One bootstrap from `baseline-v1` against a workspace, with its timings recorded |
| TR-B | The template's next bump of Node (24), pnpm (11) or TypeScript past what the runners and typescript-eslint support | WATCH | Each pin is recorded in IMPLEMENTATION-STATUS; move it when the runners and tools do |

Accepted, and worth knowing before you change them: TR-C (the Workers build
output is ignored by the shared ESLint preset), TR-D (no remote Turborepo
cache: each lane builds its app from scratch).
