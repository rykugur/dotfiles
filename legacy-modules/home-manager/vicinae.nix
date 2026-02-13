{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.ryk.vicinae;

  vicinaePkg = pkgs.stdenv.mkDerivation rec {
    pname = "vicinae";
    version = "0.2.1";

    src = pkgs.fetchurl {
      url =
        "https://github.com/vicinaehq/vicinae/releases/download/v${version}/vicinae-linux-x86_64-v${version}.tar.gz";
      sha256 = "sha256-c2YC/i2yul3IKasUexKrW0o87HE8X60aBzkS+I7nnQI=";
    };

    nativeBuildInputs = with pkgs; [ autoPatchelfHook qt6.wrapQtAppsHook ];
    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtsvg
      qt6.qttools
      qt6.qtwayland
      qt6.qtdeclarative
      qt6.qt5compat
      kdePackages.qtkeychain
      kdePackages.layer-shell-qt
      openssl
      cmark-gfm
      libqalculate
      minizip
      stdenv.cc.cc.lib
      abseil-cpp
      protobuf
      nodejs
      wayland
    ];

    unpackPhase = ''
      tar -xzf $src
    '';

    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      cp bin/vicinae $out/bin/
      cp share/applications/vicinae.desktop $out/share/applications/
      chmod +x $out/bin/vicinae
    '';

    dontWrapQtApps = true;

    preFixup = ''
      wrapQtApp "$out/bin/vicinae" --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath buildInputs
      }
    '';

    meta = {
      description =
        "A focused launcher for your desktop — native, fast, extensible";
      homepage = "https://github.com/vicinaehq/vicinae";
      license = pkgs.lib.licenses.gpl3;
      maintainers = [ ];
      platforms = pkgs.lib.platforms.linux;
    };
  };
in {
  options.ryk.vicinae = {
    enable = lib.mkEnableOption "Enable vicinae home-manager module.";
    autoStart =
      lib.mkEnableOption "Whether to autostart vicinae server or not.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ vicinaePkg ];

    systemd.user.services.vicinae = {
      Unit = {
        Description = "Vicinae launcher daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${vicinaePkg}/bin/vicinae server";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install =
        mkIf cfg.autoStart { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
