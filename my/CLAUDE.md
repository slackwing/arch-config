# CLAUDE.md — workflow hub

This directory (`~/.config/my`) is the portable home of my personal workflow —
it travels to new machines. A Claude started here is my general-purpose
assistant for system work and for starting/continuing projects. This file is
an index: it tells you how I work and where the details live. When a project
directory has its own CLAUDE.md, defer to it.

## The machine

- Arch Linux + Hyprland. All config lives in `~/.config`, which is a git repo
  (commit style: `feat(config): ...`, terse). Key spots: `hypr/hyprland.conf`
  (+ `hypr/scripts/`), `waybar/`, `nvim/`, `tmux/`. Keyd remaps live outside
  the repo at `/etc/keyd/default.conf`.
- Power policy (lid → suspend-then-hibernate, hibernate at 5% battery,
  mouse-wake disabled, 40G /swapfile) is applied by `setup-power.sh` here —
  run once with sudo per machine; the resulting config lives outside the
  repo in `/etc`. User-side idle timeouts: `hypr/hypridle.conf`.
- `myrc2.sh` in this directory holds my aliases and functions and is the
  single best reference for how I do things (deploys, navigation, upgrades).
  Read it before inventing a procedure. `upgrade` = full system update.
- `README.md` here documents machine-portability steps (tmux symlinks,
  userChrome, SSH keys) and the web-deploy discipline. Read it before any
  server sync work.

## Projects

- Everything is under `$SRC = ~/src`.
- Small/experimental projects live one-directory-per-project in
  `~/src/feathers` (alias `feathers`; warns because it exits any worktree).
  `~/src/darkfeather` is the PRIVATE (non-public) repo — for things I don't
  want to divulge; be mindful about copying its contents elsewhere.
- **Shared numbering**: feathers and darkfeather share one sequence of
  2-digit lowercase-hex project numbers (`<nn>.<kebab-name>`, e.g.
  `12.kaprekar`, `16.the-wildfire`). After `19` comes `1a`, not `20`.
  (`0g` is a one-off misnumbering, grandfathered in — treat it as sitting
  between `0f` and `10`; don't imitate it.) To find the next free number,
  list BOTH directories and take the highest allocated + 1; as of 2026-07
  that is `17` (darkfeather's wildfire took 16).
- Major projects graduate to their own repo under `~/src/<name>` (e.g.
  `manuscript-studio`, `hobby-server`) instead of a feathers number.
- `$SRC/worktree-<name>` checkouts (`worktree <name>` navigates, `worktrees`
  lists) are a legacy of my pre-Claude workflow — I rarely work in them now,
  but old uncommitted work may still live there.
- Per-project rules: check the project dir for CLAUDE.md (e.g.
  `feathers/11.sxiv`, `feathers/12.kaprekar`, `~/src/hobby-server`).
- **Always commit AND push** after finishing work in `~/.config`,
  `feathers`, `darkfeather`, `manuscript-studio`, `hobby-server`,
  and `~/src/minutes` — don't ask, don't leave work unpushed.

## Shared website auth

- All websites share ONE login system (one account per person,
  per-website roles, `hobby_session` SSO cookie, invite/reset links),
  served by `~/src/hobby-server` with its console at
  andrewcheong.com/admin. New sites must use it — never roll
  per-site auth. Full integration guide:
  `~/src/hobby-server/docs/SHARED_AUTH.md`. (rv predates it and
  still uses its own legacy login.)
- **Underscore convention**: files the shared system reaches into by
  path live at the same place in every site and start with `_`:
  `<site>/_invite/` (invite / set-password page) and `<site>/_email/`
  (email templates + admin preview; the console sends them). Users
  carry `initial`/`color` (avatar) and `email`, all admin-set. Sending
  needs the `email:` SMTP block in the VM's hobby-server config.

## Web deployment

- `feathers/foundry/website/html/` (alias `html` from feathers) mirrors
  directly to my web server's `/var/www/html/` via rsync.
- The hxh site is BUILT: `cd ~/src/feathers/foundry/website && npm run
  check` (esbuild bundle + node/jsdom tests) before `ws_prod`; the
  bundle `html/hxh/hxh.js` is committed. See `html/CLAUDE.md` there.
- `ws_prod` (master branch only) syncs production; `ws_stag` syncs
  `.staging/`. Both DELETE what they don't find — the server is a mirror of
  the repo EXCEPT paths protected in rsync filters and
  `~/.config/my/website_sync_excludes`. Never add server-persistent state
  without updating those filters. Full doctrine in `README.md` here.
- `ws_ssh` = SSH to the server (GCP, key `~/.ssh/id_ed25519_gcp_202512`).
  Run `ssha` first to load the key into the agent (needed before any
  server sync/SSH work in a fresh session).
- Other syncs: `dashboard_sync` (sxiv dashboard), `wsj_prod`/`wsj_stag`
  (journal). All defined in `myrc2.sh`.
- `manuscript-studio` deploys via its `install.sh` from GitHub main
  (`cp_deploy` copies the one-liner). `hobby-server` mirrors the
  manuscript-studio pattern — see its CLAUDE.md.
- Delete branches once merged to master; the branch list should mean
  "unmerged work".
- **Two sessions, one master (2026-09-19, Andrew's ask):** when more than
  one Claude works on the hxh site, each works in its OWN worktree
  (`git worktree add -b <job> ~/src/worktree-<job> origin/master`) and
  never edits the shared `~/src/feathers` checkout. Before merging or
  deploying, take the shared lock: `~/.config/my/deploy-lock.sh wait
  <session-name>` (a dir in /tmp; `status` shows who holds it). While
  holding it: `git fetch`, rebase the branch on origin/master (rebuild
  the committed hxh bundle with `npm run build` after any merge — never
  resolve it by hand), `npm run check`, push the branch straight to
  master (`git push origin <job>:master`), rsync from the worktree, and
  for hobby-server push to main and run the VM install. Then
  `deploy-lock.sh release`. Same for hobby-server (one lock covers both).
- **Several Claudes at once** (common on hxh): develop in a worktree
  (`git worktree add -b <job> ~/src/worktree-<job> origin/master`), and
  take `flock -w 900 /tmp/claude-deploy.lock` around merge-to-master +
  push + deploy only (write who/why to `/tmp/claude-deploy.lock.holder`
  while holding it). Protocol: `/tmp/CLAUDE-LOCK-README.txt`. Fetch and
  merge origin before taking the lock; deploy from the main checkout.

## UI writing (all projects)

- NO verbose labels, hints, or explainer sentences in UIs. Real products
  don't caption their affordances ("Drag to reorder — the top person's…").
  If an affordance needs explaining, the design is wrong or the words
  belong in a hover `title` tooltip. Buttons/labels: one or two words.

## Daily tools

- `sxiva` — my CLI (built in `feathers/11.sxiv`) for daily minutes/points;
  data in `~/src/minutes/data` (`$SXIVA_DATA`). `minutes` navigates there.
- tmux workspaces (`tmux-main`, `tmux-sxiva`, `tmux-wildfire` in this dir,
  symlinked into `~/.local/bin`) are the legacy per-project workflow, being
  superseded by Claude scratchpads started here.
