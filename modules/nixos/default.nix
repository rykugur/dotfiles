{ config, lib, ... }:
let cfg = config.rhx;
in {
  imports = [
    ./1password.nix
    ./btrfs.nix
    ./docker.nix
    ./gamemode.nix
    ./gnome.nix
    ./kde.nix
    ./obs-studio.nix
    ./pipewire.nix
    ./razer.nix
    ./ssh.nix
    ./starcitizen.nix
    ./steam.nix
    ./vfio.nix
    ./vr.nix
    ./winboat.nix

    # keebs
    ./wooting.nix
    ./zsa.nix

    # vms
    ./distrobox.nix
    ./virtman.nix
  ];

  options.rhx.keyboardVendor = lib.mkOption {
    type = lib.types.enum [ "wooting" "zsa" "none" ];
    default = "none";
    description = ''
      Which keyboard vendor to enable udev rules for. Choose one of:
      - "wooting"
      - "zsa"
      - "none"
    '';
  };

  config = {
    rhx.wooting.enable = lib.mkIf (cfg.keyboardVendor == "wooting") true;
    rhx.zsa.enable = lib.mkIf (cfg.keyboardVendor == "zsa") true;
  };
}
