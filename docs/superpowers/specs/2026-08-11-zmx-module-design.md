# ZMX Home Manager Module Design

## Goal

Provide a reusable Home Manager `zmx` module that installs ZMX and zmx-session-manager, then exposes the current ZMX session in Starship when Starship is enabled.

## Package integration

`overlays/default.nix` exposes the zmx-session-manager flake's default package as `pkgs.zsm`:

```nix
zsm = inputs.zmx-session-manager.packages.${system}.default;
```

Resolving the flake output in the shared overlay keeps consumers platform-agnostic and matches the repository's existing aliases for input packages. The module installs `pkgs.zmx` on every platform supported by nixpkgs and `pkgs.zsm` only on Linux, where the upstream input publishes it.

## Module interface

Add `modules/terminal/zmx.nix`, exporting `flake.modules.homeManager.zmx`. It has no custom options; importing it means ZMX tooling is wanted.

The `developer` group imports `zmx` from `self.modules.homeManager` and removes its direct `zmx` and `zsm` declarations. This keeps the group declarative while making ZMX available to another group or host without copying package and prompt configuration.

## Starship integration

The module reads `config.programs.starship.enable`. Only when it is true, the module adds:

```nix
programs.starship.settings.env_var.ZMX_SESSION = {
  symbol = " ";
  format = "[$symbol$env_value]($style) ";
  description = "zmx session name";
  style = "bold magenta";
};
```

The `starship` module gains a `programs.starship.prependFormat` list option, defaulting to `[]`. It constructs the configured format from that ordered list followed by the existing base format (`$all$line_break$kubernetes$line_break$character`). Its default produces byte-for-byte the existing prompt.

When Starship is enabled, the ZMX module adds `${env_var.ZMX_SESSION}` to `prependFormat` with `lib.mkBefore`; future modules can contribute their own prefix without duplicating or replacing the base string. Nix only orders list definitions—its string option type rejects two competing values—so this composition point is required to retain the existing format safely.

Starship omits the env-var module when `ZMX_SESSION` is not set, so the prompt is unchanged outside a ZMX session.

## Constraints

- Preserve all existing Starship settings and its base format.
- Do not add Starship or enable it as a side effect of enabling ZMX.
- Use package attributes from the repository overlay, not direct system-indexed flake input references in Home Manager consumers.
- Keep `zmx-session-manager` Linux-only insofar as its upstream flake publishes packages only for Linux platforms; the module must not make Darwin evaluation fail.

## Verification

- Evaluate the jezrien Home Manager configuration and confirm `zmx` and `zsm` are in its package set.
- Evaluate the merged Starship settings and confirm the format begins with `${env_var.ZMX_SESSION}` while retaining the existing base format.
- Confirm the env-var module fields match the upstream ZMX recommendation.
- Evaluate the taln/Darwin configuration to confirm the Linux-only package condition does not introduce an unsupported package reference.
