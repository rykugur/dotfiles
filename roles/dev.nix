{
  config,
  lib,
  pkgs,
  username,
  outputs,
  ...
}:
let
  cfg = config.ryk.roles.dev;
in
{
  options.ryk.roles.dev.enable = lib.mkEnableOption "Enable dev role";

  config = lib.mkIf cfg.enable {
    # enable nixOS modules for desktop role
    # ryk = {};

    # home-manager config
    home-manager.users.${username} = {
      imports = with outputs.modules.homeManager; [
        atuin
        git
        jujutsu
        zed-editor
      ];

      home.packages = with pkgs; [
        bun
        just
        prettierd
        stylua
        vscode
        bruno
        insomnia
      ];
    };
  };
}
