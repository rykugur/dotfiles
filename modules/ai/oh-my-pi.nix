{ ... }:
let
  version = "16.4.8";

  mkOhMyPi =
    pkgs:
    let
      inherit (pkgs) lib;

      sources = {
        x86_64-linux = {
          asset = "omp-linux-x64";
          sha256 = "0k44hqgrcxzp8anb8r58y3nvxh1zri1favb0vbwn73dq0mg7gw6d";
        };
        aarch64-linux = {
          asset = "omp-linux-arm64";
          sha256 = "1ib9qq92651gy164w3h1xzhn40a6gzmj89i2pax3akfbi3b5grcw";
        };
        x86_64-darwin = {
          asset = "omp-darwin-x64";
          sha256 = "06yapmx4p9yp173xy05l8lsldkvn0slghgqhhpjgd0a3yj0011ry";
        };
        aarch64-darwin = {
          asset = "omp-darwin-arm64";
          sha256 = "0ivlbl21fy8ri8c9yz3yqgll80n0dl3cv4aqr5aycsis2pfx78rx";
        };
      };

      srcInfo =
        sources.${pkgs.stdenv.hostPlatform.system}
          or (throw "oh-my-pi is not packaged for ${pkgs.stdenv.hostPlatform.system}");

      linuxLibPath = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.glibc
        pkgs.openssl
        pkgs.zlib
      ];
    in
    pkgs.stdenv.mkDerivation {
      pname = "oh-my-pi";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${srcInfo.asset}";
        inherit (srcInfo) sha256;
      };

      dontUnpack = true;
      dontStrip = pkgs.stdenv.isLinux;
      dontPatchELF = pkgs.stdenv.isLinux;

      nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
        pkgs.makeWrapper
        pkgs.patchelf
      ];

      installPhase =
        if pkgs.stdenv.isLinux then
          ''
            runHook preInstall

            install -Dm755 "$src" "$out/libexec/omp"
            patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" "$out/libexec/omp"
            makeWrapper "$out/libexec/omp" "$out/bin/omp" \
              --prefix LD_LIBRARY_PATH : "${linuxLibPath}"

            runHook postInstall
          ''
        else
          ''
            runHook preInstall

            install -Dm755 "$src" "$out/bin/omp"

            runHook postInstall
          '';

      doInstallCheck = pkgs.stdenv.isLinux;
      installCheckPhase = ''
        runHook preInstallCheck

        HOME="$TMPDIR" "$out/bin/omp" --version >/dev/null

        runHook postInstallCheck
      '';

      meta = {
        description = "Oh My Pi coding agent";
        homepage = "https://github.com/can1357/oh-my-pi";
        license = lib.licenses.mit;
        mainProgram = "omp";
        platforms = builtins.attrNames sources;
      };
    };
in
{
  flake.modules.homeManager.oh-my-pi =
    { pkgs, ... }:
    {
      home.packages = [ (mkOhMyPi pkgs) ];
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.oh-my-pi = mkOhMyPi pkgs;
    };
}
