# mechanical keyboards
{pkgs, ...}: {
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = [
    pkgs.via
    pkgs.vial
  ];

  services.udev.packages = [pkgs.via pkgs.vial];
}
