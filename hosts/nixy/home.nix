{ ... }: {
  imports = [ ../../modules/home-manager/helix.nix ];

  ryk.helix.enable = true;

  ### leave me alone
  programs.home-manager.enable = true;
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  home.stateVersion = "25.05";
}
