{ pkgs
, lib
, stdenv
, fetchzip
}:
let
  mkStarsectorMod =
    { src
    , name
    , deps ? [ ]
    }: stdenv.mkDerivation {
      inherit name src;

      phases = [ "installPhase" ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -rf $src/* $out

        runHook postInstall
      '';
    };

  fetch7zip = pkgs.fetch7zip;
in
rec {
  lazylib = mkStarsectorMod {
    name = "lazylib";
    src = fetchzip {
      url = "https://github.com/LazyWizard/lazylib/releases/download/2.8b/LazyLib.2.8b.zip";
      sha256 = "sha256-0HypoB/ZW/1HdHJMTxEktnbSBWQBjvuxAgoq6c2uzbs=";
    };
  };

  magiclib = mkStarsectorMod {
    name = "magiclib";
    src = fetchzip {
      url = "https://github.com/MagicLibStarsector/MagicLib/releases/latest/download/MagicLib.zip";
      sha256 = "sha256-ZoLyuoYbT2Lfm4cx6aR68ytbQDe+qgsHARZGIhNKvVQ=";
    };
  };

  nexerelin = mkStarsectorMod {
    name = "nexerelin";
    src = fetchzip {
      url = "https://github.com/Histidine91/Nexerelin/releases/download/v0.11.1b/Nexerelin_0.11.1b.zip";
      sha256 = "sha256-S7M4fAgwl4IxTPGle9RkzD00ElWNYGN+BLPaJMZLWoQ=";
    };
    deps = [ lazylib magiclib ];
  };

  zz_graphicslib = mkStarsectorMod {
    name = "zz_graphicslib";
    src = fetch7zip {
      name = "zz_graphicslib";
      url = "https://bitbucket.org/DarkRevenant/graphicslib/downloads/GraphicsLib_1.9.0.7z";
      sha256 = "sha256-LwLO5A0Af6vKJcnGWk9rylzhvwolWCJV5aqoaY+6ra4=";
    };
    deps = [ lazylib ];
  };
}
