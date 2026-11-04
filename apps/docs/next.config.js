import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const workspaceRoot = path.join(__dirname, "../..");

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Required by @opennextjs/cloudflare, which bundles `.next/standalone/**`
  // into the Worker. Traced (and Turbopack rooted) at the monorepo root, so
  // @repo/ui and the other workspace packages resolve from it.
  output: "standalone",
  outputFileTracingRoot: workspaceRoot,
  turbopack: { root: workspaceRoot },
  // There is no image optimiser on Workers without an Images binding; every
  // image here is an SVG, which Next serves unoptimised anyway.
  images: { unoptimized: true },
  // Dev server only (`next build` ignores it): orun.work's live Preview tab
  // loads `next dev` from the preview's own host, and Next.js refuses the hot
  // reload and other /_next/* dev requests from an origin it is not told about.
  allowedDevOrigins: ["*.orun-preview.app", "preview-gateway-stage.oruncloud.workers.dev"],
};

export default nextConfig;
