{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      packages = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
        vasher-lxc-image = inputs.nixos-generators.nixosGenerate {
          inherit pkgs;
          format = "proxmox-lxc";
          modules = [ ./_seed.nix ];
        };
      };
    };
}
