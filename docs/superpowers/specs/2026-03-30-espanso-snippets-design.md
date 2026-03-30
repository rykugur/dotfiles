# Espanso Snippets Module Design

**Date:** 2026-03-30  
**Status:** Approved

## Overview

Create a home-manager module for Espanso that provides text snippet expansion across Linux and macOS. Snippets are defined in Nix and rendered via the home-manager `services.espanso` module.

## Location

`modules/terminal/espanso.nix`

## Structure

```nix
{ ... }:
{
  flake.modules.homeManager.espanso =
    { pkgs, config, lib, ... }:
    {
      options.espanso = {
        snippets = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [ ];
          description = "List of Espanso snippet definitions";
        };
      };

      config = lib.mkIf config.services.espanso.enable {
        services.espanso.configs.default = {
          matches = config.espanso.snippets;
        };
      };
    };
}
```

## Snippets

| Trigger | Replace |
|---------|---------|
| `:install-helix` | `curl -fsSL sh.ryk.sh/install-helix-deb \| bash -s --` |

## Usage

Import the module in a host's home configuration:

```nix
imports = [ self.modules.homeManager.espanso ];

services.espanso.enable = true;
espanso.snippets = [
  { trigger = ":install-helix"; replace = "curl -fsSL sh.ryk.sh/install-helix-deb | bash -s --"; }
];
```

## Compatibility

- **Linux:** Works with Wayland and X11
- **macOS:** Supported via home-manager's `services.espanso` (Darwin support merged in PR #5268)
- **Trigger prefix:** `:colon` (can be changed per snippet if needed)

## Implementation Notes

- Uses `services.espanso.configs` which accepts YAML values directly
- Espanso package is managed separately (not installed by this module)
- Module only configures the service and snippets
