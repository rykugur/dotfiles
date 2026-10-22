# Personal Instructions

- Prefer simple, maintainable solutions.
- Keep changes focused on the request.
- Verify significant changes before reporting completion.

## Project Change History

- Arcanum is the single wiki and the source of truth for changes and decisions made with Dusty in dotfiles, homelab, and other personal projects. Those repos keep no `wiki/` and no `docs/`; they hold code, a `README.md`, and a `CLAUDE.md` that points at Arcanum.
- Before completing such work, read Arcanum's `CLAUDE.md`, `index.md`, and the recent entries in the current month's `log/YYYY-MM.md`. Record each change or related batch as a new entry there — heading `## [YYYY-MM-DD] <verb> | <title>` followed by `**Project:** <name>` — stating what changed, why, decisions and tradeoffs, affected paths, and observed results or uncertainty. Update the relevant page under `wiki/Projects/<Name>/` for durable decisions.
- Keep durable documentation in Arcanum, not in the project repo. If Arcanum is unavailable, report that the change was not logged rather than claiming it was.

## System Configuration

- Never run a command that activates or changes the CURRENT machine's NixOS, nix-darwin, or Home Manager configuration — i.e. no `--target-host`/remote target, or any invocation defaulting to the local system. This rule includes live `nixos-rebuild switch`/`boot`, `darwin-rebuild switch`, and `home-manager switch` runs against the machine the agent is running on.
- Activating a REMOTE host (`nixos-rebuild`/`darwin-rebuild switch --target-host <other-host>`, never the current machine) is allowed, but only after asking and receiving explicit permission for that specific run. Do not run a remote switch unprompted, and do not treat an earlier approval as standing permission for a later run.
- Commands that only evaluate, build, check, or perform a dry run are allowed, for local or remote targets. `nix flake check` is allowed.
