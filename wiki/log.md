# Swoleflake LLM Wiki — Log

Append-only chronological record. Entries use the machine-friendly prefix `## [YYYY-MM-DD] <verb> | <title>`.

---

## [2026-06-03] init | Bootstrapped llm-wiki structure and core pages

- Created `wiki/` with `raw/`, `concepts/`, `entities/`, `sources/` subdirs.
- Wrote `wiki/schema.md` (domain-specific instructions, workflows, Nix/Swoleflake conventions, mempalace notes).
- Wrote `wiki/raw/README.md` (guidance for the immutable source layer).
- Synthesized initial core pages by surveying the repo:
  - `overview.md`
  - `architecture.md`
  - `hosts.md`
  - `modules.md`
  - `history.md`
  - `ai-agents.md`
- Created `index.md` (catalog) and this `log.md`.
- All pages include frontmatter, relative cross-links, and pointers back to raw sources (CLAUDE.md, README, design docs, flake.nix, module files).
- The wiki now provides a persistent synthesized view of the dendritic flake, hosts, module system, migration history, and especially the AI agent provisioning (which distributes the llm-wiki skill itself).

This establishes the three layers:
- Raw (starting guidance + future drops)
- Wiki (the generated pages above)
- Schema (the rules in schema.md)

Future work will be driven by actual ingest of the superpowers design docs (deeper dives), code changes, user questions, and periodic lint passes.

## [2026-06-03] ingest | 2026-03-23 Dendritic Module Conversion design spec

- Created `wiki/sources/2026-03-23-dendritic-module-conversion.md` with faithful summary of the key decisions (no enable opts, import=activation, domain categories, cross-class modules, auto-discovery).
- Updated [history.md](history.md) to cross-reference the new source page and note it as primary literature.
- Updated [index.md](index.md) to list the new source summary under Sources.
- This serves as the first concrete "ingest one source → touch multiple pages" example for the wiki.

## [2026-06-03] update | Supporting integration changes for new wiki

- Added "wiki" room to root `mempalace.yaml` so the memory palace tool knows about the curated knowledge base (complements the llm-wiki skill).
- Added a "LLM Wiki (knowledge base)" section to root `CLAUDE.md` so coding agents are directed to use `wiki/index.md` + `wiki/schema.md` when relevant.
- Populated `wiki/concepts/README.md` and `wiki/entities/README.md` so the category directories are useful and git-trackable.
- These changes were made as part of the initial creation pass.

## [2026-06-10] update | gnome module hygiene pass

- Fixed `modules/desktop/gnome.nix`:
  - `services.xserver.displayManager.gdm` → `services.displayManager.gdm` (option moved out of xserver namespace in NixOS 24.05+; old path is a deprecated alias).
  - `check-alive-timeout = "30000"` → `lib.hm.gvariant.mkUint32 30000` (the dconf key is uint32; passing a string stored the wrong gvariant type).
  - `defaultApplications."image/*"` → explicit MIME types (jpeg/png/gif/webp/bmp/tiff/svg+xml). xdg-mime does not expand wildcards, so the wildcard form was silently inert.
- Verified `modules/desktop/kde.nix` already uses the new flat `services.displayManager.sddm` form — no fix needed there.
- No new wiki pages warranted (localized bugfix). Conventions captured here for future reference: when configuring dconf via home-manager, use `lib.hm.gvariant.mk{Uint32,Int32,Double,...}` for typed keys; MIME associations must be enumerated explicitly.

## [2026-07-09] ingest | Steam-for-Linux slow-download investigation (jezrien)

- Created [sources/steam-linux-slow-download-investigation.md](sources/steam-linux-slow-download-investigation.md): systematic-debugging pass on jezrien's slow Steam downloads (~50–110 Mbps vs 917 Mbps on Windows / 780 Mbps raw on same box).
- **Conclusion**: root cause is a Valve Steam-for-Linux client bug (kernel-confirmed `app_limited` + ~177 KB receive window + ~1.2 Mbps/conn; upstream #13024), NOT jezrien's network/driver/DNS/disk (all measured fast/clean). No NixOS config fix exists.
- Recorded that the `r8125` driver swap in `modules/hosts/jezrien/_configuration.nix` was an attempted fix that did **not** resolve it (kept as a valid offload improvement only), and that a CDN-blackhole module (#13378) was considered and **rejected** (throttle is receiver-side, not CDN selection). Only real workaround: DepotDownloader for big pulls.
- Updated [hosts.md](hosts.md): added a Networking bullet + a note under jezrien pointing at the investigation and clarifying the `r8125` code.
- Updated [index.md](index.md): listed the new source page under Sources; bumped "last major update" to 2026-07-09.
- Note: borderline vs the schema's "no transient debugging notes" rule — kept because it explains an existing config decision (the `r8125` blacklist) and prevents re-investigating the host or building the doomed blackhole module.

## [2026-07-12] ingest | User-definable default shell (`ryk.defaultShell`)

- New feature merged to master: a single `ryk.defaultShell` option (enum `fish` | `nushell` | `bash`, default `nushell`) as the source of truth for the primary user's login shell and the shell active everywhere.
- Architecture: system-canonical option in `modules/nixos/login-shell.nix` (sets `users.users.<name>.shell` + `/etc/shells`) + a home-manager aggregator `modules/shell/default-shell.nix` (`flake.modules.homeManager.shell`) that mirrors the value via `osConfig.ryk.defaultShell or "nushell"` and gates the `fish`/`nushell` submodules with `lib.mkIf` (whole-attrset, no package leakage).
- Moved `modules/nushell.nix` → `modules/shell/nushell.nix`. Removed hardcoded nushell launch from `kitty`/`tmux`/`zellij`/`ghostty` — they now inherit `$SHELL`.
- Updated [modules.md](modules.md): fixed the tree (nushell relocated, added `default-shell`/`login-shell`) and added a "Default shell" section documenting the mechanism + the `ryk.*` config-value option namespace.
- Updated [hosts.md](hosts.md): noted jezrien's login shell is now `ryk.defaultShell`-driven.
- Updated [index.md](index.md): bumped "last major update" to 2026-07-12.
- Primary artifacts: `docs/superpowers/specs/2026-07-10-default-shell-design.md` and `docs/superpowers/plans/2026-07-10-default-shell.md`.
- Open follow-up (not done): `modules/ai/herdr.nix:11` `terminal.default_shell = "nu"` is a separate hardcoded spot that could also follow the option — left as a user judgment call.

## [2026-07-27] ingest | dusty-nfs autofs mount on taln (darwin)

- Implemented the Darwin case the 2026-06-12 design had deferred: `modules/misc/dusty-nfs.nix` now also defines `flake.modules.darwin.dusty-nfs`, mounting the TrueNAS `dusty-nfs` share on-demand at `~/Documents/dusty-nfs` via macOS autofs (direct map `/etc/auto_dusty_nfs` → neutral mountpoint `/System/Volumes/Data/mnt/dusty-nfs`, `/etc/auto_master` splice in `postActivation`, home-manager `mkOutOfStoreSymlink`). Wired into `modules/hosts/taln/default.nix`.
- **Blocker found + fixed (separate commit):** `modules/ai/herdr.nix`'s `installHerdrOmpIntegration` home-manager activation ran `herdr integration install omp`, which exits non-zero when `~/.omp/agent/extensions` is missing. Under `set -e` that aborted the *entire* nix-darwin activation before any `postActivation` step — silently skipping the NFS splice (and everything else after home-manager). Fix: `mkdir -p` the extensions dir before the install. This was failing every `darwin-rebuild switch` on taln, not just NFS.
- Also cleaned up a pre-existing manual `/etc/fstab` NFSv3 entry (IP-based) for the same share that macOS's built-in `/- -static` map was auto-mounting at `/System/Volumes/Data/mnt/default_pool/dusty-nfs` — removed so there is one declarative mechanism.
- Design decision: the darwin variant inlines its 3-line home-manager symlink rather than splitting into a separate `flake.modules.homeManager.dusty-nfs` (YAGNI — Darwin-only, no cross-host reuse).
- Updated [modules.md](modules.md) (new "dusty-nfs (NFS automount)" section) and [hosts.md](hosts.md) (taln NFS bullet).
- Primary artifacts: `docs/superpowers/specs/2026-07-27-dusty-nfs-darwin-design.md`, `docs/superpowers/plans/2026-07-27-dusty-nfs-darwin.md`.
- Deferred: off-LAN graceful-failure check (validated on-LAN only; `soft,timeo=50` set).

## [2026-07-30] ingest | Vasher cache and status dashboard

- Created [entities/vasher.md](entities/vasher.md), consolidating the LXC’s cache/prebuild role, the serialized freshness and promotion boundary, reduced Jezrien target, resource envelope, retention, deployment, and operator commands.
- Recorded the static React work ledger: Catppuccin Mocha styling, Caddy’s LAN-only port `5080`, three curated read-only endpoints, five-second polling, and bounded status/history/log artifacts. No Node service, SSR, journal API, remote build delegation, or dashboard writes were introduced.
- Updated [hosts.md](hosts.md) with the dashboard entry point and entity link; updated [index.md](index.md) with the new entity catalog entry and last-major-update date.

---


