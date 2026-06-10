{ self, ... }:
{
  flake.modules.nixos.gnome =
    { pkgs, username, ... }:
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

        displayManager.gdm.enable = true;

        xserver = {
          enable = true;
          desktopManager.gnome.enable = true;
        };
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.gnome ];
    };

  flake.modules.homeManager.gnome =
    { lib, ... }:
    let
      loupe = [ "org.gnome.Loupe.desktop" ];
    in
    {
      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "image/jpeg" = loupe;
            "image/png" = loupe;
            "image/gif" = loupe;
            "image/webp" = loupe;
            "image/bmp" = loupe;
            "image/tiff" = loupe;
            "image/svg+xml" = loupe;
          };
        };
      };
      dconf = {
        enable = true;
        settings = {
          "org/gnome/mutter" = {
            auto-maximize = false;
            check-alive-timeout = lib.hm.gvariant.mkUint32 30000;
            experimental-features = [ "scale-monitor-framebuffer" ];
          };
          "org/gnome/desktop/interface" = { color-scheme = lib.mkDefault "prefer-dark"; };
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
