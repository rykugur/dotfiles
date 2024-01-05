{ config, inputs, lib, pkgs, ... }: {
  programs.firefox = {
    enable = true;
    enableGnomeExtensions = true;

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
