# ishar — comin pilot container (x86_64-linux, Proxmox LXC on roshar).
# Deliberately minimal: its job is to prove pull-based deployment, not to run
# a workload.
{ inputs, self, ... }:
{
  imports = [ ./_image.nix ];

  flake.nixosConfigurations.ishar = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.vasher-cache
      self.modules.nixos.comin
      ./_role.nix
      ./_platform-lxc.nix
      # Pilot: deploy from this branch, not master. Flip to "master" (and let
      # the host converge on that commit) before the branch is merged.
      { ryk.comin.branch = "comin-rollout-plan"; }
    ];
    specialArgs = { inherit inputs; };
  };
}
