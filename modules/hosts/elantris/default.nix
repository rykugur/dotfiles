# elantris — isolated OpenRig agent world VM (x86_64-linux, QEMU guest on
# roshar, VLAN 199). Installed once with nixos-anywhere + disko; every
# change after that arrives through comin, pulling the public repo over
# HTTPS with no credential. See [[OpenRig Agent World]] in Arcanum.
#
# Deliberately NOT importing `self.modules.nixos.vasher-cache`, any
# Tailscale module, or home-manager for Dusty's user: this guest gets
# nothing of Dusty's. Its only secret is its own dedicated OpenRouter key,
# added later by Dusty directly into `secrets.yaml`.
{ inputs, self, ... }:
{
  imports = [ ./_installer.nix ];

  flake.nixosConfigurations.elantris = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.pve-vm
      self.modules.nixos.comin
      ./_disko.nix
      ./_role.nix
      ./_comin-branch.nix
    ];
    specialArgs = { inherit inputs; };
  };
}
