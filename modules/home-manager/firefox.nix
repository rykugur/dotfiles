{ config, inputs, lib, pkgs, ... }: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      cfg = {
        enableGnomeExtensions = true;
      };
    };

    profiles = {
      default = {
        id = 0;
        userChrome = ''
          #TabsToolbar {
            display: none;
          }
        '';
      };
    };
  };
}
