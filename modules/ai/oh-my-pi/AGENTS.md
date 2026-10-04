# Personal Instructions

- Prefer simple, maintainable solutions.
- Keep changes focused on the request.
- Verify significant changes before reporting completion.

## System Configuration

- Never run a command that activates or changes the current NixOS, nix-darwin, or Home Manager configuration. This rule includes live `nixos-rebuild`, `darwin-rebuild`, and `home-manager switch` runs.
- Commands that only evaluate, build, check, or perform a dry run are allowed. `nix flake check` is allowed.
