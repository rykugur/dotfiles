{ inputs, self, ... }:
{
  perSystem =
    { lib, system, ... }:
    {
      # `proxmox-lxc.nix` builds the CT template itself, so this needs no
      # nixos-generators (deprecated since its upstreaming in 25.05).
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        ishar-lxc-image =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            # comin ships in the template, so the CT starts converging from
            # its first boot instead of waiting for a hand deploy. The branch
            # setting has to be here too, or the seed polls master.
            modules = [
              ./_seed.nix
              self.modules.nixos.comin
              ./_comin-branch.nix
            ];
          }).config.system.build.tarball;
      };
    };
}
