{ lib, modulesPath, ... }:
{
  # Minimal first-boot system for the Proxmox CT template. Its only job is to
  # come up on the network with SSH so the real `hoid` closure can be pushed
  # with `nixos-rebuild --flake .#hoid --target-host`.
  #
  # `lxc-container.nix`, not `proxmox-lxc.nix`: the latter builds a tarball
  # without the pieces a container needs to actually boot — `register-nix-paths`
  # (which creates `/nix/var/nix/profiles/system`, required by nixos-rebuild),
  # `systemd-udev-trigger` (networkd depends on it inside containers), and a
  # DHCP network matching veth links, which the stock
  # `99-ethernet-default-dhcp` deliberately excludes. A CT built without them
  # boots to a getty with no address and no system profile.
  imports = [ "${modulesPath}/virtualisation/lxc-container.nix" ];

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  networking = {
    hostName = "hoid";
    useDHCP = lib.mkForce true;
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ];
  };

  services.openssh = {
    enable = true;
    startWhenNeeded = lib.mkForce false;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Seed-only root access: the deployed system disables root login and is
  # updated as `dusty` with passwordless sudo.
  users.users.root.openssh.authorizedKeys.keys = [
    # personal
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgLk3xlBbjNte2VW4ZE6ewngB07bZ1MdkOBnJFFnzQV"
    # jezrien
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO+urk8awyDQhOmONXIsAcHzaIlvHSiTD4rL/5GAHo6D"
  ];

  system.stateVersion = "24.11";
}
