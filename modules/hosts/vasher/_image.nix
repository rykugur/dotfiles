{ inputs, ... }:
{
  perSystem =
    { lib, system, ... }:
    {
      # `proxmox-lxc.nix` builds the CT template itself, so this needs no
      # nixos-generators (deprecated since its upstreaming in 25.05).
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        vasher-lxc-image =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [ ./_seed.nix ];
          }).config.system.build.tarball;
      };
    };
}
