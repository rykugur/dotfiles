# ZMX Home Manager Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable ZMX Home Manager module that installs ZMX/zsm and adds a ZMX session indicator to the Starship prompt.

**Architecture:** Keep `zsm` exposed as the existing `pkgs.zsm` overlay alias. Add a small compositional `prependFormat` option to the Starship module so terminal modules can extend the prompt without replacing its base format. The ZMX module owns its packages and conditional Starship contribution; the developer group only imports that module.

**Tech Stack:** Nix flakes, flake-parts, NixOS, Home Manager, Starship.

## Global Constraints

- Preserve the existing Starship base format exactly: `$all$line_break$kubernetes$line_break$character`.
- Do not enable Starship as a side effect of enabling ZMX.
- Install `pkgs.zmx` on supported nixpkgs platforms; install `pkgs.zsm` only on Linux because the upstream flake publishes it only for Linux.
- Consume zmx-session-manager through the existing `pkgs.zsm` overlay alias; do not add a system-indexed input reference to a Home Manager consumer.
- The ZMX indicator must use the upstream-recommended symbol, format, description, and `bold magenta` style.

---

### Task 1: Add composable Starship format prefixes

**Files:**
- Modify: `modules/shell/starship.nix:1-27`

**Interfaces:**
- Produces: `programs.starship.prependFormat :: listOf str`, default `[]`.
- Consumes: every contributor supplies complete Starship format fragments, ordered before the module’s fixed base format.

- [ ] **Step 1: Write the failing configuration assertion**

Run:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.starship { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; programs.starship.prependFormat = [ "\${env_var.ZMX_SESSION}" ]; } ]; }; in configuration.config.programs.starship.settings.format'
```

Expected: FAIL with `The option programs.starship.prependFormat does not exist`.

- [ ] **Step 2: Implement the format-prefix option and preserve all existing Starship settings**

Change the module body to declare the list option, move its current configuration below `config`, and construct `settings.format` from the prefixes followed by the current base string:

```nix
{ ... }:
{
  flake.modules.homeManager.starship =
    { config, lib, ... }:
    {
      options.programs.starship.prependFormat = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Format fragments rendered before Starship's base prompt format.";
      };

      config.programs.starship = {
        enable = true;

        enableFishIntegration = config.programs.fish.enable;
        enableNushellIntegration = config.programs.nushell.enable;
        enableZshIntegration = config.programs.zsh.enable;

        settings = {
          format = lib.concatStrings (
            config.programs.starship.prependFormat
            ++ [ "$all$line_break$kubernetes$line_break$character" ]
          );
          hostname = { ssh_symbol = ""; };
          nix_shell = {
            format = "[$name]($style)";
            heuristic = true;
          };
          kubernetes = {
            disabled = false;
            format = "[$symbol$context( \\($namespace\\))]($style)";
          };
        };
      };
    };
}
```

- [ ] **Step 3: Verify an extended prompt composes correctly**

Run:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.starship { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; programs.starship.prependFormat = [ "\${env_var.ZMX_SESSION}" ]; } ]; }; in configuration.config.programs.starship.settings.format'
```

Expected: `${env_var.ZMX_SESSION}$all$line_break$kubernetes$line_break$character`.

- [ ] **Step 4: Commit the compositional Starship configuration**

```bash
git add modules/shell/starship.nix
git commit -m "feat(starship): support prompt format prefixes"
```

### Task 2: Create the ZMX module and migrate the developer group

**Files:**
- Create: `modules/terminal/zmx.nix`
- Modify: `modules/groups/developer.nix:6-24, 41-67`
- Verify: `overlays/default.nix:14-76` retains `zsm = inputs.zmx-session-manager.packages.${system}.default;`

**Interfaces:**
- Consumes: `pkgs.zmx`, Linux-only `pkgs.zsm`, `programs.starship.enable`, and `programs.starship.prependFormat` from Task 1.
- Produces: `flake.modules.homeManager.zmx`, which adds ZMX packages and, when Starship is enabled, the `ZMX_SESSION` env-var prompt module.

- [ ] **Step 1: Write the failing module-export assertion**

Run:

```bash
nix eval .#modules.homeManager.zmx --apply 'module: true'
```

Expected: FAIL because `modules/terminal/zmx.nix` does not exist and flake-parts has no `homeManager.zmx` module output.

- [ ] **Step 2: Create the focused ZMX Home Manager module**

Create `modules/terminal/zmx.nix`:

```nix
{ ... }:
{
  flake.modules.homeManager.zmx =
    { config, lib, pkgs, ... }:
    {
      home.packages = [ pkgs.zmx ] ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.zsm ];

      programs.starship = lib.mkIf config.programs.starship.enable {
        prependFormat = lib.mkBefore [ "\${env_var.ZMX_SESSION}" ];
        settings.env_var.ZMX_SESSION = {
          symbol = " ";
          format = "[$symbol$env_value]($style) ";
          description = "zmx session name";
          style = "bold magenta";
        };
      };
    };
}
```

- [ ] **Step 3: Replace direct developer-group packages with the ZMX module import**

In the terminal imports in `modules/groups/developer.nix`, add `zmx`:

```nix
zellij
zmx
zoxide
```

Remove these direct package entries:

```nix
zmx # testing lightweight zellij replacement
zsm # zmx-session-manager
```

Do not change the existing `pkgs.zsm` overlay alias.

- [ ] **Step 4: Verify the merged Linux Home Manager configuration**

Run:

```bash
nix eval --raw .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.format
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.env_var.ZMX_SESSION
nix eval .#modules.homeManager.zmx --apply 'module: true'
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.dusty.home.packages --apply 'packages: map (package: package.name) (builtins.filter (package: builtins.match "^(zmx|zsm).*" package.name != null) packages)'
nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = "aarch64-darwin"; }; configuration = flake.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ flake.modules.homeManager.zmx { home.username = "test"; home.homeDirectory = "/tmp/test"; home.stateVersion = "23.11"; } ]; }; in toString (builtins.length configuration.config.home.packages)'
```

Expected:
- Format is `${env_var.ZMX_SESSION}$all$line_break$kubernetes$line_break$character`.
- The JSON object has `symbol` ` `, `format` `[$symbol$env_value]($style) `, `description` `zmx session name`, and `style` `bold magenta`.
- The exported ZMX module evaluates successfully.
- The Linux package-name list contains one `zmx-*` and one `zsm-*` entry.
- The synthetic aarch64-darwin Home Manager configuration evaluates successfully, proving no unsupported `zsm` reference is forced on Darwin.

- [ ] **Step 5: Format and commit the ZMX module cutover**

```bash
nixfmt modules/terminal/zmx.nix modules/groups/developer.nix modules/shell/starship.nix
nix eval .#nixosConfigurations.jezrien.config.home-manager.users.dusty.programs.starship.settings.format
git add modules/terminal/zmx.nix modules/groups/developer.nix modules/shell/starship.nix
git commit -m "feat(terminal): add zmx home module"
```
