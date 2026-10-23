{ inputs, ... }:
{
  perSystem =
    { lib, system, ... }:
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        rysn-installer-iso =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              (
                { lib, modulesPath, ... }:
                {
                  imports = [
                    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
                    "${modulesPath}/profiles/qemu-guest.nix"
                  ];
                  services.openssh = {
                    enable = true;
                    settings.PermitRootLogin = "prohibit-password";
                  };
                  users.users.root.openssh.authorizedKeys.keys = import ../../misc/_dusty-ssh-keys.nix;
                  services.qemuGuest.enable = true;
                  image.baseName = lib.mkForce "rysn-installer";
                  nix.settings.experimental-features = [ "nix-command" "flakes" ];
                }
              )
            ];
          }).config.system.build.isoImage;
      };
    };
}
