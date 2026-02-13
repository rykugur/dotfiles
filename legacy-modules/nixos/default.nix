{ config, lib, ... }:
let
  cfg = config.ryk;
in
{
  imports = [
    ./1password.nix
    ./btrfs.nix
    ./gamemode.nix
    ./gnome.nix
    ./kde.nix
    ./obs-studio.nix
    ./pipewire.nix
    ./razer.nix
    ./ssh.nix
    ./steam.nix
    ./vfio.nix

    # keebs
    ./wooting.nix
    ./zsa.nix

    # vms
    ./distrobox.nix
    ./virtman.nix
  ];

  options.ryk.keyboardVendor = lib.mkOption {
    type = lib.types.enum [
      "wooting"
      "zsa"
      "none"
    ];
    default = "none";
    description = ''
      Which keyboard vendor to enable udev rules for. Choose one of:
      - "wooting"
      - "zsa"
      - "none"
    '';
  };

  config = {
    ryk.wooting.enable = lib.mkIf (cfg.keyboardVendor == "wooting") true;
    ryk.zsa.enable = lib.mkIf (cfg.keyboardVendor == "zsa") true;
  };
}
