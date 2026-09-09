# Cache provider ownership

Date: 2026-09-09
Status: Approved for implementation

## Purpose

A binary cache supplies signed Nix store paths. A substituter is a URL that Nix queries for those paths.

The repository stores each external cache URL and public key once. The root flake trusts caches for all current cache-backed inputs. Each installed feature enables only the daemon cache that it uses.

## Provider registry

Add a small pure Nix file that maps provider names to `url` and `key` values. It contains these providers:

- `hyprland`
- `niri`
- `nix-gaming`
- `nix-citizen`
- `helix`
- `nix-community`
- `thalheim`

Do not include `cache.nixos.org`. NixOS supplies that default cache and key. Do not include `pi` because the repository no longer contains the related input or module.

The registry contains data only. It does not define module options or apply Nix settings.

## Bootstrap configuration

`flake.nix` imports the provider registry. It builds `nixConfig.extra-substituters` and `nixConfig.extra-trusted-public-keys` from every registry entry.

This scope supports the first build after a user enables an optional checked-in input. It also removes the stale Pi trust and adds missing Niri, Nix Community, and Thalheim trust.

## Feature ownership

A feature-owned NixOS module applies the daemon cache for that feature. A Home Manager module must not own the system daemon setting.

`modules/dev/helix.nix` defines both `flake.modules.nixos.helix` and `flake.modules.homeManager.helix`. The NixOS module applies the Helix cache and installs the shared Home Manager module for root. The host imports `self.modules.nixos.helix`, and the old `helix-root.nix` file is removed.

`modules/desktop/hyprland.nix` applies the Hyprland cache inside its existing enabled branch. Disabled Hyprland configurations do not add the cache to the installed daemon.

The two Star Citizen NixOS modules continue to apply the Nix Citizen and Nix Gaming caches. They read the values from the registry instead of repeating the URL and key strings.

The upstream Niri NixOS module already applies its cache when Niri is enabled. The local code does not add a second Niri daemon declaration.

Stylix and `sops-nix` expose caches in their upstream flake configuration. Their providers stay in the root bootstrap set and the Vasher prebuild set. This change does not add new global daemon settings to desktop hosts.

## Vasher

Vasher imports every registry provider for its upstream build caches. This follows the selected policy for all current cache-backed flake inputs and prevents drift between root bootstrap settings and prebuild settings.

Vasher relies on the NixOS default for `cache.nixos.org`. It does not repeat the default URL or public key.

The Vasher cache module adds its LAN substituter only in consumer mode. If `ryk.vasherCache.serve` is true, the server does not query or trust its own cache.

The `vasher` service account is removed from `nix.settings.trusted-users`. The account can use system-defined substituters without trusted-user authority.

The existing `experimental-features` value in the Vasher role becomes a list of strings. Current NixOS requires that type, and the correction permits full configuration evaluation.

## Security properties

Public signing keys are not secrets. Nix accepts a cache result only when a trusted key validates its signature. The default `require-sigs` behavior remains unchanged.

The Vasher cache uses HTTP on the local network. Its signature protects store-path integrity, but HTTP does not protect availability or hide requests.

The private Harmonia signing key remains in the encrypted secret store. This work does not read or change that secret.

## Documentation

Update `wiki/architecture.md` to list the current providers. Remove the stale Pi and Chaotic or Nyx claim.

## Verification

Run these checks after implementation:

1. Evaluate the Jezrien substituter and trusted-key lists.
2. Make sure that Jezrien contains Vasher, Helix, Niri, Nix Citizen, Nix Gaming, and `cache.nixos.org`.
3. Evaluate the Vasher substituter and trusted-key lists.
4. Make sure that Vasher contains every registry provider and `cache.nixos.org`.
5. Make sure that Vasher does not contain its own LAN URL or public key.
6. Make sure that neither evaluated configuration contains the Pi cache.
7. Run `nix flake check`.
8. Request `nix-cache-info` from every resulting cache endpoint.

The implementation is complete only when all checks succeed.
