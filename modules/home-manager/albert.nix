{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.albert;
  dracula-albert-theme = pkgs.fetchFromGitHub {
    owner = "dracula";
    repo = "albert";
    rev = "526b4e666203e462aed87de8fa2158cf8ecda5cf";
    sha256 = "sha256-me8DXSAxvssmUkZoyH6L9GWBy2PkiQtZVhS6EqLXaQE=";
  };
  albertOverride = pkgs.albert.overrideAttrs (old: {
    postInstall = ''
      ${old.postInstall or ""}
      mkdir -p $out/share/albert/org.albert.frontend.widgetboxmodel/themes/
      cp ${dracula-albert-theme.out}/DraculaPurple.qss $out/share/albert/widgetsboxmodel/themes/
    '';
  });
in {
  options.rhx.albert = {
    enable = lib.mkEnableOption "Enable albert home-manager module.";
  };

  config = lib.mkIf cfg.enable { home.packages = [ albertOverride ]; };
}
