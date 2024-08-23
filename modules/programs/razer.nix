{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.razer;
in {
  options.modules.programs.razer.enable =
    lib.mkEnableOption "Enable Razer module";

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
