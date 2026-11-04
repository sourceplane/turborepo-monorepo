import { afterEach, describe, expect, it, vi } from "vitest";
import type { ReactElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { Button } from "@repo/ui/button";
import { Card } from "@repo/ui/card";
import { Code } from "@repo/ui/code";

// The three components the template's apps share through @repo/ui. Both
// apps render the Button; Card and Code are the package's other exports.

describe("@repo/ui Button", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("renders its children in a button carrying the class it is given", () => {
    const html = renderToStaticMarkup(
      <Button appName="web" className="secondary">
        Open alert
      </Button>,
    );
    expect(html).toBe('<button class="secondary">Open alert</button>');
  });

  it("greets the app it is rendered in when it is clicked", () => {
    const alert = vi.fn();
    vi.stubGlobal("alert", alert);
    for (const appName of ["web", "docs"]) {
      const button = Button({ appName, children: "Open alert" }) as ReactElement<{ onClick: () => void }>;
      button.props.onClick();
      expect(alert).toHaveBeenLastCalledWith(`Hello from your ${appName} app!`);
    }
    expect(alert).toHaveBeenCalledTimes(2);
  });
});

describe("@repo/ui Card", () => {
  it("links out in a new tab with the template's campaign parameters", () => {
    const html = renderToStaticMarkup(
      <Card title="Docs" href="https://turborepo.dev/docs" className="card">
        Find in-depth information about Turborepo features and API.
      </Card>,
    );
    expect(html).toContain(
      'href="https://turborepo.dev/docs?utm_source=create-turbo&amp;utm_medium=basic&amp;utm_campaign=create-turbo"',
    );
    expect(html).toContain('class="card"');
    expect(html).toContain('rel="noopener noreferrer"');
    expect(html).toContain('target="_blank"');
    expect(html).toContain("<h2>Docs <span>-&gt;</span></h2>");
    expect(html).toContain("<p>Find in-depth information about Turborepo features and API.</p>");
  });
});

describe("@repo/ui Code", () => {
  it("renders its children as code with the class it is given", () => {
    expect(renderToStaticMarkup(<Code className="code">pnpm dev</Code>)).toBe('<code class="code">pnpm dev</code>');
  });
});
