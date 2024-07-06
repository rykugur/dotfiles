{ config, lib, pkgs, username, ... }:
let cfg = config.modules.programs.oh-my-posh;
in {
  options.modules.programs.oh-my-posh.enable =
    lib.mkEnableOption "Enable oh-my-posh.";
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ oh-my-posh ];
    };
  };
}
