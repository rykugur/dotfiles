# Project Zomboid Helix Tooling Design

## Goal

Make Helix provide Project Zomboid API completion and diagnostics for Lua mod projects by combining EmmyLua LSP from nixpkgs-unstable with Umbrella's EmmyLua type stubs.

## Scope

- Pin Umbrella (`PZ-Umbrella/Umbrella`) as a non-flake flake input.
- Install and configure `pkgs.emmylua-ls` through the existing Home Manager Helix module.
- Configure Helix's Lua language to use EmmyLua LSP.
- Make Umbrella's `library/` directory globally available to EmmyLua in every Helix Lua workspace.
- Preserve the existing `luaformatter` formatter.

No Project Zomboid mod repository, user-home configuration file, or Lua formatter behavior changes.

## Architecture

`flake.nix` owns the reproducible Umbrella revision through a `flake = false` input. `modules/dev/helix.nix` receives the input already exposed by the module's argument set and supplies the immutable Nix-store path `${inputs.umbrella}/library` to EmmyLua's `workspace.library` configuration.

Helix launches `pkgs.emmylua-ls` as the sole language server for Lua files. EmmyLua consumes its client configuration under the `emmylua` scope, then indexes both each opened workspace and the configured Umbrella library. This produces PZ API type information without committing `.emmyrc.json` files to individual mods.

## Components

### Flake input

Add the non-flake `umbrella` input at `github:PZ-Umbrella/Umbrella`. The lock file records its exact revision and content hash.

### Helix language server

Replace the local `lua-language-server` language-server entry with `emmylua-ls`:

- `command = lib.getExe pkgs.emmylua-ls`
- `config.workspace.library = [ "${inputs.umbrella}/library" ]`

This is the documented EmmyLua library-path configuration and aligns with Umbrella's recommended EmmyLua integration.

### Lua language binding

Set the existing Lua language configuration's `language-servers` to `[ "emmylua-ls" ]`. Keep `auto-format = true` and the `luaformatter` command unchanged.

## Error Handling and Compatibility

The Nix evaluation fails early if the pinned input or `pkgs.emmylua-ls` is unavailable. No runtime fallback to LuaLS is retained: Umbrella documents EmmyLua as its recommended server and notes that LuaLS lacks support for advanced stub features.

The configuration applies on every platform supported by this flake, subject to `pkgs.emmylua-ls` platform availability. It does not depend on writable local paths or project-specific configuration.

## Verification

1. Run `nix flake check --no-build` to validate the flake and all evaluated configurations.
2. Evaluate the target Home Manager configuration or generated Helix language configuration to confirm it contains the `emmylua_ls` executable and pinned Umbrella `library/` path.
3. Smoke-test the generated Helix configuration by opening a Lua file in a temporary workspace and confirming that Helix starts `emmylua-ls` without a configuration error.

## Sources

- Umbrella setup: https://github.com/PZ-Umbrella/Umbrella
- EmmyLua configuration guide: https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/main/docs/config/emmyrc_json_EN.md
- Helix language configuration: https://docs.helix-editor.com/languages.html
