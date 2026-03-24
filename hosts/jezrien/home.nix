{ pkgs, ... }:
{
  imports = [
    ../../home
    # TODO: still needed for ryk.* option definitions used by legacy desktop modules (niri, etc.)
    ../../legacy-modules/home-manager
    ./home-packages.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
    "nexusmods-app-unfree-0.21.1"
  ];

  sops.secrets = {
    homelab_ssh_private_key = {
      # temporary hack... maybe
      sopsFile = ../../hosts/jezrien/secrets.yaml;
    };
  };

  home.packages = [
    pkgs.beyond-all-reason

    pkgs.kalker
  ];

  programs.ghostty.settings.window-decoration = "none";

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
