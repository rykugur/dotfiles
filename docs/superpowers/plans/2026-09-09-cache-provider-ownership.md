# Cache Provider Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store each cache provider once, apply daemon caches through their features, and remove stale or excessive trust.

**Architecture:** A pure root file stores cache URLs and public keys. The root flake and Vasher consume the full provider set, while feature modules consume only their related entries.

**Tech Stack:** Nix flakes, flake-parts, NixOS modules, Home Manager, Harmonia

## Global Constraints

- Keep bootstrap trust for all current cache-backed flake inputs.
- Do not add `cache.nixos.org` to the provider registry because NixOS supplies it.
- Remove the Pi cache because its input and module no longer exist.
- Keep the upstream Niri daemon cache unchanged.
- Preserve unrelated user changes in `modules/hosts/jezrien/_configuration.nix`.
- Do not read or change encrypted secret files or private signing keys.

---

### Task 1: Add the cache provider registry

**Files:**
- Create: `cache-providers.nix`
- Modify: `flake.nix:1-4,190-205`

**Interfaces:**
- Produces: An attribute set whose values contain `url :: string` and `key :: string`.
- Consumes: No project interface.

- [ ] **Step 1: Record the current failure**

Run:

```bash
nix eval --json --file ./cache-providers.nix
```

Expected: FAIL because `cache-providers.nix` does not exist.

- [ ] **Step 2: Create the provider registry**

Create `cache-providers.nix` with this content:

```nix
{
  helix = {
    url = "https://helix.cachix.org";
    key = "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=";
  };
  hyprland = {
    url = "https://hyprland.cachix.org";
    key = "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=";
  };
  niri = {
    url = "https://niri.cachix.org";
    key = "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=";
  };
  nix-citizen = {
    url = "https://nix-citizen.cachix.org";
    key = "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=";
  };
  nix-community = {
    url = "https://nix-community.cachix.org";
    key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };
  nix-gaming = {
    url = "https://nix-gaming.cachix.org";
    key = "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=";
  };
  thalheim = {
    url = "https://cache.thalheim.io";
    key = "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc=";
  };
}
```

- [ ] **Step 3: Make the root flake consume every provider**

Wrap the root attribute set in this binding at the start of `flake.nix`:

```nix
let
  cacheProviders = builtins.attrValues (import ./cache-providers.nix);
in
{
```

Replace the existing `nixConfig` block with:

```nix
  nixConfig = {
    extra-substituters = map (provider: provider.url) cacheProviders;
    extra-trusted-public-keys = map (provider: provider.key) cacheProviders;
  };
```

This replacement removes Pi and adds Niri, Nix Community, and Thalheim.

- [ ] **Step 4: Evaluate the registry**

Run:

```bash
nix eval --json --file ./cache-providers.nix
```

Expected: PASS with seven entries. No entry contains `pi` or `cache.nixos.org`.

- [ ] **Step 5: Make sure that the flake accepts the generated settings**

Run:

```bash
nix flake metadata --no-write-lock-file
```

Expected: PASS. Nix can report that new flake settings need approval.

- [ ] **Step 6: Commit the registry**

```bash
git add cache-providers.nix flake.nix
git commit -m "nix: centralize cache provider trust"
```

---

### Task 2: Move daemon caches into feature modules

**Files:**
- Modify: `modules/dev/helix.nix:1-5`
- Delete: `modules/dev/helix-root.nix`
- Modify: `modules/hosts/jezrien/default.nix:22`
- Modify: `modules/hosts/jezrien/_configuration.nix:26-35`
- Modify: `modules/desktop/hyprland.nix:1-3,70-85`
- Modify: `modules/gaming/starcitizen.nix:1-20`
- Modify: `modules/gaming/starcitizen-lite.nix:1-13,41-50`

**Interfaces:**
- Consumes: Provider records from `cache-providers.nix`.
- Produces: `flake.modules.nixos.helix` and the existing feature-specific daemon settings.

- [ ] **Step 1: Record the current Jezrien cache set**

Run:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.nix.settings.substituters
```

Expected: PASS. The result contains Helix, Niri, Nix Citizen, Nix Gaming, Vasher, and `cache.nixos.org`.

- [ ] **Step 2: Add the NixOS half of the Helix module**

Change the start of `modules/dev/helix.nix` to this structure. Keep the existing Home Manager module body unchanged after the new NixOS module.

```nix
{ inputs, self, ... }:
let
  cacheProvider = (import ../../cache-providers.nix).helix;
in
{
  flake.modules.nixos.helix =
    { config, lib, ... }:
    let
      username = config.ryk.username;
      primaryStateVersion =
        config.home-manager.users.${username}.home.stateVersion or "23.11";
    in
    {
      nix.settings = {
        substituters = [ cacheProvider.url ];
        trusted-public-keys = [ cacheProvider.key ];
      };

      home-manager.users.root = {
        imports = [ self.modules.homeManager.helix ];

        home = {
          username = "root";
          homeDirectory = "/root";
          stateVersion = lib.mkDefault primaryStateVersion;
        };
      };
    };

  flake.modules.homeManager.helix =
```

Delete `modules/dev/helix-root.nix` after the content is present in `modules/dev/helix.nix`.

- [ ] **Step 3: Switch Jezrien to the owned Helix module**

Replace this import in `modules/hosts/jezrien/default.nix`:

```nix
        self.modules.nixos.helix-root
```

with:

```nix
        self.modules.nixos.helix
```

In `modules/hosts/jezrien/_configuration.nix`, keep `trusted-users` and remove only these feature-specific settings:

```nix
    substituters = [ "https://helix.cachix.org" ];
    trusted-public-keys = [
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
```

- [ ] **Step 4: Apply the Hyprland provider when enabled**

Add this binding before the output attribute set in `modules/desktop/hyprland.nix`:

```nix
let
  cacheProvider = (import ../../cache-providers.nix).hyprland;
in
```

Add this block inside the existing `lib.mkIf cfg.enable` result:

```nix
        nix.settings = {
          substituters = [ cacheProvider.url ];
          trusted-public-keys = [ cacheProvider.key ];
        };
```

- [ ] **Step 5: Source the Star Citizen provider values from the registry**

Add this binding before the output attribute set in both Star Citizen files:

```nix
let
  cacheProviders = import ../../cache-providers.nix;
in
```

Replace each repeated cache block with:

```nix
      nix.settings = {
        substituters = [
          cacheProviders.nix-citizen.url
          cacheProviders.nix-gaming.url
        ];
        trusted-public-keys = [
          cacheProviders.nix-citizen.key
          cacheProviders.nix-gaming.key
        ];
      };
```

Preserve the different indentation that surrounds the block in each file.

- [ ] **Step 6: Evaluate Jezrien after the ownership move**

Run:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.nix.settings | jq '{substituters, trusted_public_keys: .["trusted-public-keys"]}'
```

Expected: PASS. The daemon set still contains Helix, Niri, Nix Citizen, Nix Gaming, Vasher, and `cache.nixos.org`.

Run:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.home-manager.users.root.programs.helix.enable
```

Expected: `true`.

- [ ] **Step 7: Commit the feature ownership move**

```bash
git add modules/dev/helix.nix modules/dev/helix-root.nix modules/hosts/jezrien/default.nix modules/hosts/jezrien/_configuration.nix modules/desktop/hyprland.nix modules/gaming/starcitizen.nix modules/gaming/starcitizen-lite.nix
git commit -m "nix: let features own daemon caches"
```

---

### Task 3: Correct Vasher cache trust

**Files:**
- Modify: `modules/hosts/vasher/_role.nix:1-36`
- Modify: `modules/nixos/vasher-cache.nix:26-33`

**Interfaces:**
- Consumes: All values from `cache-providers.nix`.
- Produces: A valid Vasher Nix configuration without self-substitution or service-account trust.

- [ ] **Step 1: Reproduce the Vasher evaluation failure**

Run:

```bash
nix eval --json .#nixosConfigurations.vasher.config.nix.settings
```

Expected: FAIL because `nix.settings.experimental-features` is a string instead of a list of strings.

- [ ] **Step 2: Replace the Vasher upstream cache block**

Change the start of `modules/hosts/vasher/_role.nix` to:

```nix
{ inputs, pkgs, ... }:
let
  cacheProviders = builtins.attrValues (import ../../../cache-providers.nix);
in
{
```

Replace `nix.settings` with:

```nix
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [ "root" ];
      auto-optimise-store = true;
      max-jobs = 1;
      cores = 4;
      substituters = map (provider: provider.url) cacheProviders;
      trusted-public-keys = map (provider: provider.key) cacheProviders;
    };
```

This replacement removes the explicit NixOS default and the orphaned Pi cache. It adds Niri, Nix Community, and Thalheim.

- [ ] **Step 3: Disable LAN self-substitution in server mode**

Replace the first element of the `lib.mkMerge` list in `modules/nixos/vasher-cache.nix` with:

```nix
        (lib.mkIf (!cfg.serve) {
          nix.settings = {
            substituters = [ cfg.url ];
            trusted-public-keys = [ publicKey ];
          };
        })
```

Keep the existing `lib.mkIf cfg.serve` service block as the second element.

- [ ] **Step 4: Evaluate the corrected Vasher settings**

Run:

```bash
nix eval --json .#nixosConfigurations.vasher.config.nix.settings | jq '{substituters, trusted_public_keys: .["trusted-public-keys"], trusted_users: .["trusted-users"]}'
```

Expected: PASS. The output contains all seven registry providers and `cache.nixos.org`.

The output must not contain:

```text
http://vasher.local.ryk.sh:5000/
vasher.swoleflake-1
pi.cachix.org
"vasher"
```

- [ ] **Step 5: Make sure that Jezrien still consumes Vasher**

Run:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.nix.settings | jq '{substituters, trusted_public_keys: .["trusted-public-keys"]}'
```

Expected: PASS. The output contains the Vasher LAN URL and `vasher.swoleflake-1` key.

- [ ] **Step 6: Commit the Vasher corrections**

```bash
git add modules/hosts/vasher/_role.nix modules/nixos/vasher-cache.nix
git commit -m "fix(vasher): correct binary cache trust"
```

---

### Task 4: Update cache documentation and run final checks

**Files:**
- Modify: `wiki/architecture.md:81`

**Interfaces:**
- Consumes: The final provider set and evaluated host configurations.
- Produces: Current architecture documentation and verification evidence.

- [ ] **Step 1: Update the provider sentence**

Replace the stale provider sentence with:

```markdown
Binary caches are configured for Hyprland, Niri, Nix Gaming, Nix Citizen, Helix, Nix Community, and Thalheim. Jezrien also consumes the Vasher LAN cache.
```

- [ ] **Step 2: Make sure that no active Pi cache declaration remains**

Use the Grep tool with this pattern:

```text
pi\.cachix\.org|pi\.cachix\.org-1
```

Search `flake.nix`, `cache-providers.nix`, `modules`, and `wiki/architecture.md`.

Expected: No matches.

- [ ] **Step 3: Evaluate the final Jezrien cache pairings**

Run:

```bash
nix eval --json .#nixosConfigurations.jezrien.config.nix.settings | jq -e '
  .substituters as $urls
  | .["trusted-public-keys"] as $keys
  | ($urls | index("http://vasher.local.ryk.sh:5000/")) != null
  and ($urls | index("https://helix.cachix.org")) != null
  and ($urls | index("https://niri.cachix.org")) != null
  and ($urls | index("https://nix-citizen.cachix.org")) != null
  and ($urls | index("https://nix-gaming.cachix.org")) != null
  and ($keys | map(startswith("vasher.swoleflake-1:")) | any)
  and ($keys | map(startswith("helix.cachix.org-1:")) | any)
  and ($keys | map(startswith("niri.cachix.org-1:")) | any)
'
```

Expected: `true` and exit status 0.

- [ ] **Step 4: Evaluate the final Vasher cache pairings**

Run:

```bash
nix eval --json .#nixosConfigurations.vasher.config.nix.settings | jq -e '
  .substituters as $urls
  | .["trusted-public-keys"] as $keys
  | ($urls | index("http://vasher.local.ryk.sh:5000/")) == null
  and ($urls | index("https://niri.cachix.org")) != null
  and ($urls | index("https://nix-community.cachix.org")) != null
  and ($urls | index("https://cache.thalheim.io")) != null
  and ($urls | map(contains("pi.cachix.org")) | any | not)
  and ($keys | map(startswith("vasher.swoleflake-1:")) | any | not)
  and ($keys | map(startswith("pi.cachix.org-1:")) | any | not)
'
```

Expected: `true` and exit status 0.

- [ ] **Step 5: Run the flake checks**

Run:

```bash
nix flake check
```

Expected: PASS with no evaluation or build failure.

- [ ] **Step 6: Probe every cache endpoint**

Use the Read tool in parallel for these URLs:

```text
https://cache.nixos.org/nix-cache-info
https://helix.cachix.org/nix-cache-info
https://hyprland.cachix.org/nix-cache-info
https://niri.cachix.org/nix-cache-info
https://nix-citizen.cachix.org/nix-cache-info
https://nix-community.cachix.org/nix-cache-info
https://nix-gaming.cachix.org/nix-cache-info
https://cache.thalheim.io/nix-cache-info
http://vasher.local.ryk.sh:5000/nix-cache-info
```

Expected: Every response reports `StoreDir: /nix/store`.

- [ ] **Step 7: Commit the documentation**

```bash
git add wiki/architecture.md
git commit -m "docs: update binary cache providers"
```
