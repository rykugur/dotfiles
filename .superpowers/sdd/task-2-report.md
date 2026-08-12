# Task 2 Report: ZMX Home Manager module

## Changed files

- `modules/terminal/zmx.nix` (new)
  - Exports `flake.modules.homeManager.zmx`.
  - Adds `pkgs.zmx` on all platforms and `pkgs.zsm` only on Linux.
  - Imports the existing `starship` module so the Task 1 `prependFormat` option is available when the ZMX module is evaluated independently.
  - Prepends `$env_var.ZMX_SESSION` with `lib.mkBefore` and configures its requested Starship `env_var` metadata.
- `modules/groups/developer.nix`
  - Imports `zmx` and removes direct `zmx`/`zsm` package entries.
  - Removes the direct `starship` import because `zmx` imports it; retaining both imports makes Nix reject the Task 1 option as declared twice.

`overlays/default.nix` was inspected and not modified; it retains `zsm = inputs.zmx-session-manager.packages.${system}.default;`. `modules/shell/starship.nix` was included in the required `git add` command but had no Task 2 diff.

## Commit

- `4352cf9abc21e867cf59b7a6dd1e0ea8e56196c1` — `feat(terminal): add zmx home module`

## Commands and results

### RED — required module-export assertion

```bash
nix eval .#modules.homeManager.zmx --apply 'module: true'
```

Exit 1 before implementation, with the expected missing `modules.homeManager.zmx` attribute error.

### Targeted evaluations after implementation

```bash
nix eval --raw .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.format
```

Exit 0; output:

```text
$env_var.ZMX_SESSION$all$line_break$kubernetes$line_break$character
```

```bash
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.env_var.ZMX_SESSION
```

Exit 0; output:

```json
{"description":"zmx session name","format":"[$symbol$env_value]($style) ","style":"bold magenta","symbol":" "}
```

```bash
nix eval .#modules.homeManager.zmx --apply 'module: true'
```

Exit 0; output: `true`.

```bash
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.packages --apply 'packages: map (package: package.name) (builtins.filter (package: builtins.match "^(zmx|zsm).*" package.name != null) packages)'
```

Exit 0; output:

```json
["zmx-0.7.0","zsm-unstable-20260807215757"]
```

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.zmx { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; } ]; }; in toString (builtins.length configuration.config.home.packages)'
```

Exit 0; output: `5`. This proves the Darwin configuration evaluates without forcing `pkgs.zsm`.

### Formatting and final targeted evaluation

```bash
nixfmt modules/terminal/zmx.nix modules/groups/developer.nix modules/shell/starship.nix
```

Exit 127: `nixfmt` is not installed on `PATH` (`error: command not found: nixfmt`). No substitute formatter was run, per the task restriction.

```bash
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.format
```

Exit 0; output:

```nix
"$env_var.ZMX_SESSION$all$line_break$kubernetes$line_break$character"
```

```bash
git add modules/terminal/zmx.nix modules/groups/developer.nix modules/shell/starship.nix
git commit -m "feat(terminal): add zmx home module"
```

Both commands exited 0; commit created as recorded above.

## Self-review

- The Linux package evaluation contains exactly one `zmx-*` and one `zsm-*` package; direct developer-group duplicates are removed.
- The Darwin evaluation succeeds and does not force the Linux-only `zsm` reference.
- The prompt format and all requested `ZMX_SESSION` values match the brief exactly.
- The literal brief module body cannot pass its standalone Darwin evaluation: its `mkIf false` definition still references the Task 1-only `prependFormat` option, which Home Manager validates even when disabled. Importing `starship` inside `zmx` supplies that option; the developer group then must not import `starship` separately, because duplicate imports redeclare the option. This is the minimal dependency cutover that satisfies every required evaluation.
- No overlays or plan/design documents were changed.
- Concern: the required `nixfmt` executable was unavailable, so formatter execution could not be verified.

## P1 review fix: decouple ZMX from Starship enablement

### Changed files

- `modules/shell/starship-format.nix` (new) — owns the enable-neutral `programs.starship.prependFormat` declaration. Its stable module key deduplicates the shared module when both Starship and ZMX import it.
- `modules/shell/starship.nix` — imports the shared format-option module and retains Starship enablement plus all Task 1 format composition behavior.
- `modules/terminal/zmx.nix` — imports only the enable-neutral shared format-option module; it no longer imports Starship and never sets `programs.starship.enable`.
- `modules/groups/developer.nix` — restores the developer group’s explicit `starship` import alongside `zmx`.

### Fix commit

- `3e1c1cd8` — `fix(zmx): decouple Starship enablement`

### Commands and results

Before the fix, the standalone Linux ZMX configuration evaluated `programs.starship.enable` to `true`, reproducing the review finding:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.zmx { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; } ]; }; in configuration.config.programs.starship.enable'
```

Exit 0; output: `true`.

After the fix, the Task 2 targeted evaluations all exited 0:

```sh
nix eval --raw .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.format
```

Output: `$env_var.ZMX_SESSION$all$line_break$kubernetes$line_break$character`.

```sh
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.env_var.ZMX_SESSION
```

Output:

```json
{"description":"zmx session name","format":"[$symbol$env_value]($style) ","style":"bold magenta","symbol":" "}
```

```sh
nix eval .#modules.homeManager.zmx --apply 'module: true'
```

Output: `true`.

```sh
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.packages --apply 'packages: map (package: package.name) (builtins.filter (package: builtins.match "^(zmx|zsm).*" package.name != null) packages)'
```

Output:

```json
["zmx-0.7.0","zsm-unstable-20260807215757"]
```

```sh
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.zmx { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; } ]; }; in toString (builtins.length configuration.config.home.packages)'
```

Output: `4`.

The required standalone Linux check also exited 0:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.zmx { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; } ]; }; in configuration.config.programs.starship.enable'
```

Output: `false`.

Task 1's standalone format interface was also retained:

```sh
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.starship { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; programs.starship.prependFormat = [ "$env_var.ZMX_SESSION" ]; } ]; }; in configuration.config.programs.starship.settings.format'
```

Output: `$env_var.ZMX_SESSION$all$line_break$kubernetes$line_break$character`.

### Self-review

- `modules/terminal/zmx.nix` has no `programs.starship.enable` definition and imports no module that enables Starship.
- The shared option declaration is owned by one module. Its stable key means the developer configuration, which imports both `starship` and `zmx`, evaluates that declaration exactly once.
- The merged Linux configuration keeps the required ZMX prompt prefix and metadata, and still installs one each of `zmx` and Linux-only `zsm`.
- Standalone ZMX evaluates on Darwin and leaves Starship disabled in the synthetic Linux configuration.
- No formatter, linter, or broad suite was run.
