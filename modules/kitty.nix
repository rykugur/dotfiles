{ self, ... }:
{
  flake.nixosModules.kitty =
    { config, ... }:
    {
      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.kitty ];
    };

  flake.homeModules.kitty =
    { pkgs, ... }:
    let
      font = "CaskaydiaCove NFM";
    in
    {
      enable = true;
      settings = {
        font_family = "${font} Regular";
        bold_font = "${font} Bold";
        italic_font = "${font} Italic";
        bold_italic_font = "${font} Bold Italic";
        font_size = 11.0;
        enable_audio_bell = "no";
        remember_window_size = "no";
        initial_window_width = "160c";
        initial_window_height = "40c";
        copy_on_select = "clipboard";
        # TODO: this should not be hard-coded; maybe move to nushell module?
        shell = "${pkgs.nushell}/bin/nu --login";
      };
      themeFile = "Catppuccin-Mocha";
    };
}
