{ config, lib, ... }:
let cfg = config.ryk.ranger;
in {
  options.ryk.ranger = {
    enable = lib.mkEnableOption "Enable ranger home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.ranger = {
      enable = true;
      plugins = [
        {
          name = "ranger-devicons";
          src = builtins.fetchGit {
            url = "https://github.com/cdump/ranger-devicons2";
            rev = "94bdcc19218681debb252475fd9d11cfd274d9b1";
          };
        }
        {
          name = "zoxide";
          src = builtins.fetchGit {
            url = "https://github.com/jchook/ranger-zoxide.git";
            rev = "363df97af34c96ea873c5b13b035413f56b12ead";
          };
        }
      ];
    };
  };
}
