# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ outputs, pkgs, username, ... }: {
  imports = [ outputs.hmModules ];
  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
      # workaround for obsidian
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  home.packages = with pkgs; [
    prettierd
    stylua

    vscode

    font-awesome
    super-slicer-latest

    # TODO: find a place for these VVV
    n0la_rcon
    dxvk
    vkd3d
    warp-terminal
    fira
    arandr
    cliphist
    pywal
    wev
    wl-clipboard
    wl-clipboard-x11
    wtype
    xorg.xrandr
    xorg.xbacklight
  ];

  rhx = {
    fuzzel.enable = true;
    git.enable = true;
    keebs.enable = true;
    kitty.enable = true;
    nushell.enable = true;
    nvim.enable = true;
    obs.enable = true;
    razer.enable = true;
    starship.enable = true;
    swappy.enable = true;
    tmux.enable = true;
    virtman.enable = true;
    zellij.enable = true;
  };

  ################## other stuff you shouldn't need to touch
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";
}
