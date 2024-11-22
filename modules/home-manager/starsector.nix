{ config, lib, pkgs, ... }:
let
  cfg = config.rhx.starsector;
  mkStarsectorMod = { name ? "nutsack", src, deps ? [ ], }:
    pkgs.stdenv.mkDerivation {
      inherit name;
      pname = name;
      inherit src;

      phases = [ "installPhase" ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -rf $src/* $out

        runHook postInstall
      '';
    };

  lazylib = mkStarsectorMod {
    name = "lazylib";
    src = pkgs.fetchzip {
      url =
        "https://github.com/LazyWizard/lazylib/releases/download/2.8b/LazyLib.2.8b.zip";
      sha256 = "sha256-0HypoB/ZW/1HdHJMTxEktnbSBWQBjvuxAgoq6c2uzbs=";
    };
  };

  magiclib = mkStarsectorMod {
    name = "magiclib";
    src = pkgs.fetchzip {
      url =
        "https://github.com/MagicLibStarsector/MagicLib/releases/download/1.4.3/MagicLib.zip";
      sha256 = "sha256-UaQbJ9EsxZr597CmUOIZeKi9mx2Y85IxqIo7y6gCPTc=";
    };
  };

  nexerelin = mkStarsectorMod {
    name = "nexerelin";
    src = pkgs.fetchzip {
      url =
        "https://github.com/Histidine91/Nexerelin/releases/download/v0.11.1b/Nexerelin_0.11.1b.zip";
      sha256 = "sha256-S7M4fAgwl4IxTPGle9RkzD00ElWNYGN+BLPaJMZLWoQ=";
    };
  };

  graphicslib = mkStarsectorMod {
    name = "graphicslib";
    src = pkgs.lib.fetch7zip {
      url =
        "https://bitbucket.org/DarkRevenant/graphicslib/downloads/GraphicsLib_1.9.0.7z";
      sha256 = "sha256-LwLO5A0Af6vKJcnGWk9rylzhvwolWCJV5aqoaY+6ra4=";
    };
  };

  # mkModsDirDrv = mods:
  #   let
  #     recursiveDeps = modDrv: [ modDrv ] ++ map recursiveDeps modDrv.deps;
  #     modDrvs = lib.unique (lib.flatten (map recursiveDeps mods));
  #   in {
  #     modsDirDrv = pkgs.stdenv.mkDerivation {
  #       name = "starsector-mods";
  #       preferLocalBuild = true;
  #       buildCommand = ''
  #         mkdir -p $out
  #         cd $out
  #         for modDrv in ${toString modDrvs}; do
  #           ln -s $modDrv/* .
  #         done
  #       '';
  #     };
  #   };

  # modsDrv = with pkgs.starsectorMods.starsectorMods;
  #   mkModDirDrv [ lazylib magiclib nexerelin graphicslib ];
in {
  options.rhx.starsector = {
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
