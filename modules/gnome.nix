{ self, ... }:
{
  flake.nixosModules.gnome =
    { config, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        gnome-tweaks

        gnomeExtensions.dash-to-dock
      ];

      services = {
        gnome = {
          gnome-browser-connector.enable = true;
          # gnome-keyring.enable = true;
        };

        xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };

      home-manager.users.${config.meta.ryk.username}.imports = [ self.homeModules.gnome ];
    };

  flake.homeModules.gnome =
    { ... }:
    {
      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "image/*" = [ "org.gnome.Loupe.desktop" ];
          };
        };
      };
      dconf = {
        enable = true;
        settings = {
          "org/gnome/mutter" = {
            auto-maximize = false;
            check-alive-timeout = "30000";
            experimental-features = [ "scale-monitor-framebuffer" ];
          };
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
          };
          "org/gnome/desktop/wm/preferences" = {
            audible-bell = false;
            visual-bell = false;
          };
          "org/gnome/desktop/peripherals/keyboard" = {
            numlock-state = true;
            remember-numlock-state = true;
          };
        };
      };
    };
}
