# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ lib, pkgs, username, ... }: {
  imports = [ ../../home/common.nix ./home-packages.nix ];

  # nixpkgs = {
  #   # You can add overlays here
  #   overlays = [
  #     outputs.overlays.additions
  #     outputs.overlays.modifications
  #     # If you want to use overlays exported from other flakes:
  #     # neovim-nightly-overlay.overlays.default

  #     # Or define it inline, for example:
  #     # (final: prev: {
  #     #   hi = final.hello.overrideAttrs (oldAttrs: {
  #     #     patches = [ ./change-hello-to-hi.patch ];
  #     #   });
  #     # })
  #   ];
  #   # Configure your nixpkgs instance
  #   config = {
  #     # Disable if you don't want unfree packages
  #     allowUnfree = true;
  #     # Workaround for https://github.com/nix-community/home-manager/issues/2942
  #     allowUnfreePredicate = _: true;
  #     # workaround for obsidian
  #     permittedInsecurePackages = [ "electron-25.9.0" ];
  #   };
  # };

  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  gtk = {
    enable = true;

    font.name = "CaskaydiaCove Nerd Font Mono 10";

    theme = {
      name = "Adementary-dark";
      package = pkgs.adementary-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        # flavor = "mocha";
        accent = "blue";
      };
    };

    gtk2.extraConfig = ''
      gtk-application-prefer-dark-theme=1
    '';

    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };

    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };

  sops.secrets = {
    homelab_ssh_private_key = {
      # temporary hack... maybe
      sopsFile = ../../hosts/jezrien/secrets.yaml;
    };
  };

  # xdg.enable = true;

  wayland.windowManager.hyprland.settings = let
    workspaces = [
      "1,monitor:DP-1"
      "2,monitor:DP-1"
      "$gamingWorkspace,monitor:DP-1"
      "$steamWorkspace,monitor:DP-2"
      "5,monitor:DP-2"
    ];
  in {
    monitor = [ "DP-1,3440x1440@175,0x1440,1" "DP-2,3440x1440@144,0x0,1,vr,0" ];

    workspace = workspaces;

    # map each workspace to two bind strings
    bind = lib.concatMap (index: [
      "$mainMod, ${index}, workspace, ${index}"
      "$mainMod SHIFT, ${index}, movetoworkspace, ${index}"
    ]) workspaces;
  };

  rhx = {
    btop.enable = true;
    keebs.enable = true;
    starsector = {
      enable = true;
      mods.enable = true;
    };
    swappy.enable = true;
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
