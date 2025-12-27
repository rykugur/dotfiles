{ config, lib, pkgs, ... }:
let
  cfg = config.ryk.starsector;
  lazylib = pkgs.fetchzip {
    url =
      "https://github.com/MagicLibStarsector/MagicLib/releases/latest/download/MagicLib.zip";
    sha256 = "sha256-jY8KYF95K4grSL9CgJ/5wckC6VpprhKqXH7PcI/KErg=";
  };
  magiclib = pkgs.fetchzip {
    url =
      "https://github.com/LazyWizard/lazylib/releases/download/3.0/LazyLib.3.0.zip";
    sha256 = "sha256-TO1jF90DRgS9cPOxFtXfff9+6Ll0S+bv2ULQ+2qsL38=";
  };
  nexerelin = pkgs.fetchzip {
    url =
      "https://github.com/Histidine91/Nexerelin/releases/download/v0.12.1/Nexerelin_0.12.1.zip";
    sha256 = "sha256-VaUNVsSlBXOTHpf+sjzY5Oim3ObbcsX8GEHr9K+wtcc=";
  };
  graphicslib = pkgs.lib.fetch7z {
    url =
      "https://bitbucket.org/DarkRevenant/graphicslib/downloads/GraphicsLib_1.12.1.7z";
    sha256 = "sha256-g1qlppfSUaA5CgrxyedJyBSZmfqr0Nq7tgNnBJ53v7A=";
  };
in {
  options.ryk.starsector = {
    enable = lib.mkEnableOption "Enable starsector home-manager module.";
    mods.enable = lib.mkEnableOption "Enable starsector mods.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.starsector ];

    home.file = lib.mkIf cfg.mods.enable {
      ".local/share/starsector/mods/lazylib" = { source = "${lazylib}"; };
      ".local/share/starsector/mods/magiclib" = { source = "${magiclib}"; };
      ".local/share/starsector/mods/nexerelin" = { source = "${nexerelin}"; };
      ".local/share/starsector/mods/graphicslib" = {
        source = "${graphicslib}/GraphicsLib"; # temporary workaround
      };
    };
  };
}
