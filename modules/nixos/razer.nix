{ config, lib, username, pkgs, ... }:
let cfg = config.rhx.razer;
in {
  options.rhx.razer.enable = lib.mkEnableOption "Enable razer nixOS module";

  config = lib.mkIf cfg.enable {
    hardware.openrazer = {
      enable = true;
      users = [ "${username}" ];
    };

    environment.systemPackages = with pkgs; [
      git
      neovim
      nix-search-cli
      polkit_gnome
      polychromatic
    ];

    users.users.${username} = { extraGroups = [ "openrazer" ]; };
  };
}
