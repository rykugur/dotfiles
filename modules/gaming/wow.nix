{ ... }:
{
  flake.modules.homeManager.wow =
    { pkgs, ... }:
    let
      wowup-cf = pkgs.wowup-cf.overrideAttrs (
        old:
        let
          version = "2.24.0-beta.6";
          src = pkgs.fetchurl {
            url = "https://github.com/WowUp/WowUp.CF/releases/download/v${version}/WowUp-CF-${version}.AppImage";
            hash = "sha256-TZ5b/DfVkEh9MsrBi2M/0dAPE1Tfd+zzquRXwprtLqQ=";
          };
          appimageContents = pkgs.appimageTools.extract {
            inherit (old) pname;
            inherit version src;
          };
        in
        {
          inherit version src;
          extraInstallCommands = ''
            install -m 444 -D ${appimageContents}/${old.pname}.desktop -t $out/share/applications
            substituteInPlace $out/share/applications/${old.pname}.desktop \
              --replace 'Exec=AppRun' 'Exec=${old.pname}'
            cp -r ${appimageContents}/usr/share/icons $out/share
          '';
        }
      );
    in
    {
      home.packages = [ wowup-cf ];
    };
}
