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

## [2026-07-27] ingest | Darwin on-demand NFS mount

- Added the deferred Darwin variant of the existing NFS automount module, using macOS autofs and a home-manager symlink.
- Fixed an independent activation-order failure: an AI-agent integration assumed a missing directory existed, which aborted the entire home-manager activation before later post-activation work could run.
- Removed a duplicate imperative NFS mount so the declarative automount is the single mechanism.
- Updated [modules.md](modules.md) and [hosts.md](hosts.md); detailed implementation history remains in the linked design artifacts.

## [2026-07-30] ingest | Vasher cache and status dashboard

- Created [entities/vasher.md](entities/vasher.md), consolidating the cache/prebuild role, serialized freshness and promotion boundary, reduced Jezrien target, resource envelope, retention, deployment, and operator lifecycle.
- Recorded the static React work ledger: Catppuccin Mocha styling, a LAN-only Caddy endpoint, three curated read-only files, five-second polling, and bounded status/history/log artifacts. No Node service, SSR, journal API, remote build delegation, or dashboard writes were introduced.
- Updated [hosts.md](hosts.md) with the dashboard summary and entity link; updated [index.md](index.md) with the new entity catalog entry and last-major-update date.

## [2026-07-30] lint | Wiki privacy audit

- Confirmed that the wiki contains no credentials, tokens, private keys, or encrypted-secret contents.
- Replaced personal identifiers, private DNS/IP details, concrete privileged-access commands, exact local service endpoints, and repository-owner references with role-oriented descriptions.
- Preserved the durable architecture, operational safety boundaries, and internal cross-references.

---


