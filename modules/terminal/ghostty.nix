{ ... }:
let
  font = "CaskaydiaCove NFM";
  # catppuccin-ghostty = pkgs.fetchFromGitHub {
  #   owner = "catppuccin";
  #   repo = "ghostty";
  #   rev = "10b3c5f56f2aa519b0e12255346a97d71a8bfeaf";
  #   sha256 = "sha256-4seUhPr6nv0ld9XMrQS4Ko9QnC1ZOEiRjENSfgHIvR0=";
  # };
in
{
  flake.modules.homeManager.ghostty =
    { pkgs, ... }:
    {
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

          window-decoration = "auto";

          app-notifications = false;

          command = "${pkgs.nushell}/bin/nu --login";

          keybind = [
            "alt+h=previous_tab"
            "alt+l=next_tab"
          ];
        };
      };
    };
}
