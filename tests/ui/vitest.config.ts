import { defineConfig } from "vitest/config";

export default defineConfig({
  // @repo/ui ships its components as .tsx source (its `exports`); the JSX in
  // them and in these tests is React's automatic runtime, as in both apps.
  esbuild: { jsx: "automatic" },
  test: {
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    environment: "node",
  },
});
