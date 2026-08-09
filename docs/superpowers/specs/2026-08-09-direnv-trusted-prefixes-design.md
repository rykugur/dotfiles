# Direnv Trusted Prefixes Design

## Goal

Allow direnv to load `.envrc` files without an explicit `direnv allow` command when they are located under the user's trusted personal workspaces:

- `/home/dusty/.dotfiles`
- `/home/dusty/projects`

## Design

Extend `modules/shell/direnv.nix`, the active Home Manager direnv module, to declaratively generate `~/.config/direnv/direnv.toml` with:

```toml
[whitelist]
prefix = ["/home/dusty/.dotfiles", "/home/dusty/projects"]
```

Direnv's native `whitelist.prefix` setting trusts `.envrc` files in each prefix and all of their descendant directories. It therefore suppresses `direnv allow` prompts for the requested locations.

## Constraints

- Keep `programs.direnv` enabled with existing `nix-direnv` and Fish, Nushell, and Zsh integrations unchanged.
- Do not use `direnvrc`; the policy is static and supported directly by `direnv.toml`.
- Trust applies to every repository below `/home/dusty/projects`, including future clones, by explicit user decision.
- Do not activate or deploy the Nix configuration.

## Verification

Evaluate the affected Home Manager configuration and inspect the generated configuration value to confirm both absolute whitelist prefixes are emitted.
