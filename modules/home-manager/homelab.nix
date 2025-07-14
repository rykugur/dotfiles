{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.homelab;
  k9s_catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "k9s";
    rev = "fdbec82284744a1fc2eb3e2d24cb92ef87ffb8b4";
    sha256 = "sha256-9h+jyEO4w0OnzeEKQXJbg9dvvWGZYQAO4MbgDn6QRzM=";
  };
in {
  options.rhx.homelab = {
    enable = lib.mkEnableOption "Enable homelab home-manager module.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      kubectl
      kubectx # also contains kubens

      kubernetes-helm
      helmfile
      kubernetes-helmPlugins.helm-secrets
    ];

    programs.k9s = {
      enable = true;
      skins = {
        catppuccin_mocha = "${k9s_catppuccin}/dist/catppuccin-mocha.yaml";
      };
      settings = { ui = { skin = "catppuccin-mocha"; }; };
    };

    programs.kubecolor = { enable = true; };
  };
}
