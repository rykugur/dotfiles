{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.modules.programs.zen-browser;
in {
  options.modules.programs.zen-browser.enable =
    lib.mkEnableOption "enable zen-browser (Firefox fork)";

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ".zen-wrapped";
        mode = "0755";
      };
    };

    home-manager.users.${username} = {
      home.packages = [ inputs.zen-browser.packages.${pkgs.system}.default ];
    };
  };
}
