{ inputs, ... }:
{
  perSystem =
    { lib, system, ... }:
    {
      # Headless installer media, same pattern as nale's — boots straight
      # into an SSH server the dedicated admin key can reach, and runs the
      # guest agent so Proxmox reports the address to pick up. Uses
      # elantris's own `_ssh-keys.nix` (one dedicated keypair), never
      # Dusty's personal/jezrien/taln keys.
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        elantris-installer-iso =
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
                  image.baseName = lib.mkForce "elantris-installer";

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
