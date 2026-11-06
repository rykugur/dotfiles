{ ... }:
{
  flake.modules.homeManager.wow =
    { pkgs, ... }:
    let
      version = "2.25.4";
      src = pkgs.fetchurl {
        url = "https://github.com/WowUp/WowUp.CF/releases/download/v${version}/WowUp-CF-${version}.AppImage";
        hash = "sha256-tKOFboaUo1wgLJ2xjLPOyqHrf8Do+oS0ZzL2fcs8Jc4=";
      };
      appimageContents = pkgs.appimageTools.extract {
        pname = "wowup-cf";
        inherit version src;
      };
      wowup-cf = pkgs.appimageTools.wrapType2 {
        pname = "wowup-cf";
        inherit version src;
        inherit (pkgs.wowup-cf) meta;
        extraInstallCommands = ''
          install -m 444 -D ${appimageContents}/wowup-cf.desktop -t $out/share/applications
          substituteInPlace $out/share/applications/wowup-cf.desktop \
            --replace 'Exec=AppRun' 'Exec=wowup-cf'
          cp -r ${appimageContents}/usr/share/icons $out/share
        '';
      };
    in
    {
      home.packages = [ wowup-cf ];
    };
}
