{ self, ... }:
{
  flake.nixosModules.ghostty =
    { config, lib, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.ghostty ];
    };

  flake.homeModules.ghostty =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.ghostty;
      font = "CaskaydiaCove NFM";
    in
    {
      imports = [
        {
          options.ryk.ghostty = {
            hideWindowDecoration = lib.mkEnableOption "Whether to hide window-decoration or not.";
            usePredefinedSize = lib.mkEnableOption "Whether to set a default term size.";
          };
        }
      ];

      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
        settings = {
          font-family = "${font}";
          font-family-bold = "${font} Bold";
          font-family-italic = "${font} Italic";
          font-family-bold-italic = "${font} Bold Italic";
          font-size = 16;

          theme = "Catppuccin Mocha";

          copy-on-select = "clipboard";

          window-inherit-working-directory = false;

          working-directory = "home";

          window-decoration = "${if cfg.hideWindowDecoration then "none" else "auto"}";
          window-height = lib.mkIf cfg.usePredefinedSize 50;
          window-width = lib.mkIf cfg.usePredefinedSize 125;

          app-notifications = false;

          command = "${pkgs.nushell}/bin/nu --login";

          keybind = [
            "alt+h=goto_split:left"
            "alt+j=goto_split:down"
            "alt+k=goto_split:up"
            "alt+l=goto_split:right"
          ];
        };
      };
    };
}
