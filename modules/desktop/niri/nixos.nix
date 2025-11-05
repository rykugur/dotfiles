{ config, inputs, lib, pkgs, username, ... }:
let cfg = config.rhx.niri;
in {
  imports = [
    inputs.niri.nixosModules.niri
    inputs.dank-material-shell.nixosModules.greeter
  ];

  options.rhx.niri = {
    enable = lib.mkEnableOption "Enable niri nixOS module";

    # bar = lib.mkOption {
    #   type =
    #     lib.types.enum [ "caelestia" "dank-material-shell" "noctalia" "none" ];
    #   default = "none";
    #   description =
    #     "Which bar/shell to use. Possible values are: caelestia, dank-material-shell, noctalia.";
    # };

    monitors = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Monitors to define.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = { gnome.gnome-keyring.enable = true; };

    # TODO: move these to HM module? some?
    environment.systemPackages = with pkgs; [
      slurp
      swappy
      wayland-utils
      wev
      wl-clipboard
      wl-clipboard-x11
      wlogout
      wtype

      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      gnome-keyring

      xwayland-satellite
    ];

    programs.niri.enable = true;

    # force-enable HM module when nixos module is enabled
    home-manager.users.${username}.rhx.niri.enable = true;
  };
}
