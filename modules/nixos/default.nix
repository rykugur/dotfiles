{ config, lib, ... }:
let cfg = config.rhx;
in {
  imports = [
    ./1password.nix
    ./btrfs.nix
    ./pipewire.nix
    ./razer.nix
    ./ssh.nix
    ./vr.nix

    # TODO: move to gaming folder
    ./gamemode.nix
    ./obs-studio.nix
    ./starcitizen.nix
    ./steam.nix

    # keebs
    # TODO: move to keebs folder
    ./wooting.nix
    ./zsa.nix

    # vms
    # TODO: move to vm folder
    ./distrobox.nix
    ./docker.nix
    ./vfio.nix
    ./virtman.nix
    ./winboat.nix
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
