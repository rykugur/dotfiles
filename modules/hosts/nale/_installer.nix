{ inputs, ... }:
{
  perSystem =
    { lib, system, ... }:
    {
      # Headless installer media: the stock minimal ISO has no authorized keys,
      # which would force a Proxmox console login to set a root password before
      # nixos-anywhere could connect. This one boots straight into an SSH
      # server Dusty's keys can reach, and runs the guest agent so Proxmox
      # reports the address to pick up.
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        nale-installer-iso =
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
                  users.users.root.openssh.authorizedKeys.keys = import ./_ssh-keys.nix;

                  services.qemuGuest.enable = true;
                  # `isoImage.isoName` was renamed to `image.fileName`, but the
                  # built file is named from `image.baseName` (iso-image.nix
                  # line 1041), so that is the one to set.
                  image.baseName = lib.mkForce "nale-installer";

                  nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                }
              )
            ];
          }).config.system.build.isoImage;
      };
    };
}
