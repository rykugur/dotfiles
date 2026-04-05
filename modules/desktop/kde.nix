{ ... }:
{
  flake.modules.nixos.kde =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.catppuccin-sddm.override {
          flavor = "mocha";
          font = "ZedMono";
          fontSize = "9";
          loginBackground = true;
        })
        (pkgs.catppuccin-kde.override { flavour = [ "mocha" ]; })
        pkgs.catppuccin-cursors.mochaBlue
      ];

      programs.ssh.askPassword =
        pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

      services = {
        power-profiles-daemon.enable = true;
        xserver.enable = true;
        displayManager.sddm = {
          enable = true;
          autoNumlock = true;
        };
        desktopManager.plasma6.enable = true;
      };
    };
}
