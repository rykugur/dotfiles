{ pkgs, ... }: {
  imports = [ ../../home ./home-packages.nix ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ];

  sops.secrets = {
    homelab_ssh_private_key = {
      # temporary hack... maybe
      sopsFile = ../../hosts/jezrien/secrets.yaml;
    };
  };

  rhx = {
    btop.enable = true;
    keebs.enable = true;
    starsector = {
      enable = true;
      mods.enable = true;
    };
    swappy.enable = true;

    hyprland = {
      monitors =
        [ "DP-1,3440x1440@175,0x1440,1" "DP-2,3440x1440@144,0x0,1,vrr,0" ];
      workspaces = [
        "1,monitor:DP-1"
        "2,monitor:DP-1"
        "$gamingWorkspace,monitor:DP-1"
        "$steamWorkspace,monitor:DP-2"
        "5,monitor:DP-2"
      ];
    };
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
