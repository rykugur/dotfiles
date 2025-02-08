{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.helix;
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "helix";
    rev = "adc26c3cdeba268962e1aef2c8acf9a691abd76e";
    sha256 = "sha256-6SIjwpfUuEmdYrwiYA5f1StFAAFmIsAY+H/Day4SMHc=";
  };
in {
  options.rhx.helix = {
    enable = lib.mkEnableOption "Enable helix home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = { theme = "catppuccin_mocha"; };
      languages = {
        language-server.typescript-language-server = with pkgs.nodePackages; {
          command =
            "${typescript-language-server}/bin/typescript-language-server";
          args = [
            "--stdio"
            "--tsserver-path=${typescript}/lib/node_modules/typescript/lib"
          ];
        };
        # language = [{
        #   name = "typescript";
        #   language-servers = [ "typescript-language-server" ];
        #   formatter = with pkgs.nodePackages; {
        #     command = "${prettier}/bin/prettier";
        #     autoformat = true;
        #     # args = [ "fmt", "--stdin", "typescript" ];
        #   };
        # }];
      };
    };

    home.file = {
      ".config/helix/themes/catppuccin_mocha.toml".source =
        "${catppuccin}/themes/default/catppuccin_mocha.toml";
    };

  };
}
