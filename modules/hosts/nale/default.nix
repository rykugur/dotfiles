# nale — comin pilot VM (x86_64-linux, QEMU guest on roshar).
# Installed once with nixos-anywhere + disko; every change after that arrives
# through comin.
{ inputs, self, ... }:
{
  imports = [ ./_installer.nix ];

  flake.nixosConfigurations.nale = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.vasher-cache
      self.modules.nixos.pve-vm
      self.modules.nixos.comin
      ./_disko.nix
      ./_role.nix
      # Pilot: deploy from this branch, not master. Flip to "master" (and let
      # the host converge on that commit) before the branch is merged.
      { ryk.comin.branch = "comin-rollout-plan"; }
      # ./_impermanence.nix — only after comin is proven without it
    ];
    specialArgs = { inherit inputs; };
  };
}
