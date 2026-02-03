{ config, lib, pkgs, ... }:
let
  cfg = config.ryk.ghostty;
  font = "CaskaydiaCove NFM";
  # catppuccin-ghostty = pkgs.fetchFromGitHub {
  #   owner = "catppuccin";
  #   repo = "ghostty";
  #   rev = "10b3c5f56f2aa519b0e12255346a97d71a8bfeaf";
  #   sha256 = "sha256-4seUhPr6nv0ld9XMrQS4Ko9QnC1ZOEiRjENSfgHIvR0=";
  # };
in {
  options.ryk.ghostty = {
    enable = lib.mkEnableOption "Enable ghostty home-manager module.";
    hideWindowDecoration =
      lib.mkEnableOption "Whether to hide window-decoration or not.";
    usePredefinedSize =
      lib.mkEnableOption "Whether to set a default term size.";
  };

  config = lib.mkIf cfg.enable {
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

        window-decoration =
          "${if cfg.hideWindowDecoration then "none" else "auto"}";
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
