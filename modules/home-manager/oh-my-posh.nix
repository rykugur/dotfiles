{ config, lib, pkgs, ... }:
let cfg = config.rhx.oh-my-posh;
in {
  options.rhx.oh-my-posh = {
    enable = lib.mkEnableOption "Enable oh-my-posh home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.oh-my-posh ];

    home.file = {
      ".config/oh-my-posh/config.omp.json".source =
        ../../configs/oh-my-posh/config.catppuccin_mocha.json;
    };
  };
}

# needs to be at the end of nushell config:
# ${pkgs.oh-my-posh}/bin/oh-my-posh init nu --config ~/.config/oh-my-posh/config.omp.json
