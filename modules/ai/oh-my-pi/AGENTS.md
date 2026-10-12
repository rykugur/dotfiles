# Personal Instructions

- Prefer simple, maintainable solutions.
- Keep changes focused on the request.
- Verify significant changes before reporting completion.

## Project Change History

- Arcanum is the source of truth for changes and decisions made with Dusty in dotfiles, homelab, and other personal projects.
- Before completing such work, read Arcanum's `CLAUDE.md`, `index.md`, and recent `log.md` entries. Record each change or related batch in `log.md`: what changed, why, decisions and tradeoffs, affected paths, and observed results or uncertainty. Update relevant wiki pages for durable decisions.
- Keep implementation details in project-local documentation. If Arcanum is unavailable, report that the change was not logged rather than claiming it was.

## System Configuration

- Never run a command that activates or changes the current NixOS, nix-darwin, or Home Manager configuration. This rule includes live `nixos-rebuild`, `darwin-rebuild`, and `home-manager switch` runs.
- Commands that only evaluate, build, check, or perform a dry run are allowed. `nix flake check` is allowed.
