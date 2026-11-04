import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { SITE_NAME } from "@repo/ui/site";

// The product's name is one literal in @repo/ui (the rebrand's seam), and
// both apps read it rather than spelling a name of their own.
const root = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const read = (rel: string) => readFileSync(join(root, rel), "utf8");

describe("the product's name", () => {
  it("is one literal in @repo/ui", () => {
    expect(SITE_NAME.trim()).not.toBe("");
    const seams = read("packages/ui/src/site.ts").match(/^export const SITE_NAME = ".*";$/gm) ?? [];
    expect(seams).toHaveLength(1);
  });

  for (const app of ["web", "docs"]) {
    it(`is the ${app} app's title`, () => {
      const layout = read(`apps/${app}/app/layout.tsx`);
      expect(layout).toContain('import { SITE_NAME } from "@repo/ui/site";');
      expect(layout).toMatch(/^\s+title: SITE_NAME,$/m);
      expect(layout).not.toMatch(/title: "/);
    });
  }
});

describe("each app", () => {
  for (const app of ["web", "docs"]) {
    it(`${app} renders the shared Button as itself`, () => {
      const page = read(`apps/${app}/app/page.tsx`);
      expect(page).toContain('import { Button } from "@repo/ui/button";');
      expect(page).toContain(`<Button appName="${app}"`);
      expect(page).toContain(`<code>apps/${app}/app/page.tsx</code>`);
    });
  }
});
