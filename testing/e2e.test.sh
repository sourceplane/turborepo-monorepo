#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, render fixtures, typecheck, lint, test,
#      build. The bootstrap's own landings are checked in the box with
#      `orun validate` and `orun plan` alone (`checks: local`; their PR's CI
#      on an `orun/BASE-…` branch is `plan` alone, and the convergence on
#      main builds, deploys and smoke-tests the site), so THIS is where a
#      site those steps refuse is caught: before the tag, not after a build
#      has merged it. Every later pull request of the site runs ci.yml's
#      verify lanes;
#   2. each app's stage lane, its own steps rendered by `orun plan` in the
#      monorepo: on a pull request (the verify profile) `build-app` — the
#      component's buildCommand, the same step the deploy profile runs —
#      `verify-build-output` and `deploy-dry-run` (`wrangler deploy --dry-run
#      --name <reponame>-<app>-stage`). They run IN THE TREE THE RUNNER STAGES
#      for the job (testing/lib/stage-job.py), with the dependency layout the
#      pinned composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. Run in a plain
#      checkout, this tier was green while the first live bootstrap's lanes
#      died in the lane layout (Turbopack: "Symlink … points out of the
#      filesystem root");
#   3. serve each built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read what the app promises: the tab carries the
#      product's name, the page is this app's own, the shared @repo/ui Button
#      is rendered and hydrated as this app, the logos, font and favicon are
#      served, and an unknown path is a 404.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: three installs and four
# builds (the landing's checks over the monorepo, then each app's stage lane in
# its own staged tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
sub="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['subdomain'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false NEXT_TELEMETRY_DISABLED=1 TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm run wire:fixture"
  "pnpm typecheck"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, the fixture render, typecheck, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2 + 3. each app's stage lane, then the app it built, served ───────────
# The 01-product landing over the repository's empty first commit: every file
# of the monorepo changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }

# The source checkout carries no build output (a CI checkout has none, so the
# plain-tree builds' is removed rather than copied in).
rm -rf "$tree/apps/web/.open-next" "$tree/apps/web/.wrangler" "$tree/apps/docs/.open-next" "$tree/apps/docs/.wrangler"

for app in web docs; do
echo "── the $app stage lane: build-app, verify-build-output, deploy-dry-run"
steps="$scratch/steps-$app"
python3 - "$scratch/plan.json" "$steps" "$app" <<'PY'
import json, pathlib, sys
plan, app = json.load(open(sys.argv[1])), sys.argv[3]
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == app and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or f"apps/{app}")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it, its dependencies what the
# pinned composition says: a lane-scoped install ran once in the source tree
# (step 1 ran the same command) and is linked in, or the job installs its own.
work="$tree/.orun/runs/e2e/$app.stage.verify-deploy/work"
[ -f "$steps/install.sh" ] || { echo "FAIL: the $app stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$steps/path")/$(cat "$steps/install.wd")" && bash -e "$steps/install.sh") \
    > "$scratch/install-$app.log" 2>&1 || { echo "FAIL: the $app lane's install step" >&2; tail -30 "$scratch/install-$app.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the $app job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in build-app verify-build-output deploy-dry-run; do
  [ -f "$steps/$step.sh" ] || { echo "FAIL: the $app stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$steps/path")" && \
        { [ -f "$steps/env" ] && source "$steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$steps/$step.sh") > "$scratch/$app-$step.log" 2>&1; then
    echo "FAIL: the $app lane's $step step" >&2; tail -40 "$scratch/$app-$step.log" >&2; exit 1
  fi
done
grep -q "EFFECTIVE_WORKER_NAME=\"$repo-$app-stage\"" "$steps/deploy-dry-run.sh" \
  || { echo "FAIL: the $app lane's dry run does not name $repo-$app-stage" >&2; exit 1; }

echo "── wrangler dev over the $app Worker"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/$app" && exec setsid pnpm exec wrangler dev --config wrangler.jsonc --ip 127.0.0.1 --port "$port" \
   --name "$repo-$app-stage" --show-interactive-dev-session=false) > "$scratch/dev-$app.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev-$app.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev-$app.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/$app/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the $app app" >&2; exit 1; }

echo "   ▸ what the $app app promises"
python3 - "$url" "$values" "$app" <<'PY'
import html, json, re, sys, urllib.error, urllib.request
base, values, app = sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3]
other = "docs" if app == "web" else "web"
name = values["productname"]
problems = []
def bad(m): problems.append(m)
def get(path):
    try:
        with urllib.request.urlopen(base + path, timeout=30) as r:
            return r.status, r.headers.get("content-type", ""), r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers.get("content-type", ""), e.read()

status, _, body = get("/")
page = body.decode()
if status != 200:
    bad(f"/ answered {status}")
title = re.search(r"<title>(.*?)</title>", page, re.S)
if not title or html.unescape(title.group(1)) != name:
    bad(f"the <title> is {title and title.group(1)!r}, not {name!r}")
if f"<code>apps/{app}/app/page.tsx</code>" not in page or f"apps/{other}/app/page.tsx" in page:
    bad(f"/ is not the {app} app's page")
if ">Open alert</button>" not in page:
    bad("the shared @repo/ui Button is not rendered")
# The page's flight data hands the client Button its props: this app's name.
if not re.search(r'\\?"appName\\?":\\?"' + app + r'\\?"', page):
    bad(f"the Button is not hydrated as the {app} app")
if "Create Next App" in page or "turborepo-monorepo" in page:
    bad("the page still carries the baseline's name")
chunks = sorted(set(re.findall(r'/_next/static/chunks/[^"\\]+\.js', page)))
if not any(b"Hello from your " in get(c)[2] for c in chunks):
    bad("no script the page loads carries the Button's click handler")

for path in ("/turborepo-light.svg", "/turborepo-dark.svg", "/orunbase.svg", "/globe.svg", "/window.svg"):
    s, ctype, body = get(path)
    if s != 200 or not ctype.startswith("image/svg+xml") or b"<svg" not in body:
        bad(f"{path} answered {s} {ctype}")
s, ctype, _ = get("/favicon.ico")
if s != 200:
    bad(f"/favicon.ico answered {s}")
fonts = sorted(set(re.findall(r'/_next/static/media/[^"\\]+\.woff', page)))
if len(fonts) < 2 or any(get(p)[0] != 200 for p in fonts):
    bad(f"the Geist fonts are not all served: {fonts}")
s, _, _ = get("/no-such-page")
if s != 404:
    bad(f"/no-such-page answered {s}, want 404")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, the shared Button and its handler, the logos, fonts and favicon, and a 404 — the {app} app's own")
PY

kill -TERM -- "-$dev_pid" 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
kill -KILL -- "-$dev_pid" 2>/dev/null || true
dev_pid=""
done

echo "e2e.test.sh: ok"
