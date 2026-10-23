# elantris — isolated OpenRig agent world VM (x86_64-linux, QEMU guest on
# roshar, VLAN 199). Installed once with nixos-anywhere + disko; every
# change after that arrives through comin, pulling the public repo over
# HTTPS with no credential. See [[OpenRig Agent World]] in Arcanum.
#
# Deliberately NOT importing `self.modules.nixos.vasher-cache` or any
# Tailscale module: this guest reaches nothing on the LAN. Its only secret
# is its own dedicated OpenRouter key, added later by Dusty directly into
# `secrets.yaml`. Home-manager was excluded for the same reason until
# a3cf6241 gave Dusty his own login here; `helix-guest` is editor config
# only — no keys, no cache, no outbound credential — so it carries none of
# that isolation.
{ inputs, self, ... }:
{
  imports = [ ./_installer.nix ];

  flake.nixosConfigurations.elantris = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.pve-vm
      self.modules.nixos.comin
      self.modules.nixos.meta
      self.modules.nixos.helix-guest
      ./_disko.nix
      ./_role.nix
      ./_world.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
