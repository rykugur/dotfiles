# ashyn — staging hypervisor (x86_64-linux, bare metal: Intel i5-6500T,
# 15G RAM, 238G NVMe, one onboard NIC, UEFI, no out-of-band console).
#
# Its job is to answer one question: can a plain NixOS host running Incus
# replace the Debian Proxmox node `roshar`? Nothing here depends on Proxmox,
# so the comparison is against PVE itself, not against proxmox-nixos.
#
# Installed once with nixos-anywhere + disko; every change after that arrives
# through comin, the same way the other comin pilots work.
{ inputs, self, ... }:
{
  flake.nixosConfigurations.ashyn = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.vasher-cache
      self.modules.nixos.comin
      self.modules.nixos.meta
      self.modules.nixos.helix-guest
      self.modules.nixos.incus-instances
      self.modules.nixos.btrfs-rollback
      ./_hardware.nix
      ./_disko.nix
      ./_role.nix
      ./_incus.nix
      ./_impermanence.nix
      { ryk.comin.url = "https://github.com/rykugur/ashyn.git"; }
    ];
    specialArgs = { inherit inputs; };
  };
}
