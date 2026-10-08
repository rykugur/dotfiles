{ ... }:
let
  font = "CaskaydiaCove NFM";
in
{
  flake.modules.homeManager.ghostty =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.ghostty;
    in
    {
      options.programs.ghostty.useFixedSize = lib.mkEnableOption "fixed window size for Ghostty";

      config.programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;
        settings = {
          font-family = font;
          font-family-bold = "${font} Bold";
          font-family-italic = "${font} Italic";
          font-family-bold-italic = "${font} Bold Italic";
          font-size = 16;

          theme = "Catppuccin Mocha";

          copy-on-select = "clipboard";

          window-inherit-working-directory = false;

          working-directory = "home";

          window-decoration = "auto";

          clipboard-paste-protection = false;
          app-notifications = false;

          keybind = [
            "ctrl+shift+h=goto_split:left"
            "ctrl+shift+j=goto_split:bottom"
            "ctrl+shift+k=goto_split:top"
            "ctrl+shift+l=goto_split:right"
          ];
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          macos-option-as-alt = true;
        }
        // lib.optionalAttrs cfg.useFixedSize {
          window-height = lib.mkDefault 50;
          window-width = lib.mkDefault 125;
        };
      };
    };
}
