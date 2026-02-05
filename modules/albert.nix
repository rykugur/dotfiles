# TODO: candidate for deletion, needs to be removed from hyprland/niri first
{ self, ... }:
{
  flake.nixosModules.albert =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.albert ];
    };

  flake.homeModules.albert =
    { pkgs, ... }:
    let
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
    in
    {
      home.packages = [ albertOverride ];
    };
}
