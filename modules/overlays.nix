{ inputs, self, ... }:
{
  flake.overlays.default =
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
    in
    {
      hyprprop = inputs.hyprland-contrib.packages.${system}.hyprprop;
      hyprland-qtutils = inputs.hyprland-qtutils.packages.${system}.default;

      opentrack = final.callPackage (self + "/pkgs/opentrack.nix") { };
      opentrack-StarCitizen = final.callPackage (self + "/pkgs/opentrack-StarCitizen.nix") { };

      kubernetes-helm-wrapped = prev.wrapHelm prev.kubernetes-helm {
        plugins = with prev.kubernetes-helmPlugins; [
          helm-diff
          helm-secrets
          helm-s3
        ];
      };

      karabiner-elements = prev.karabiner-elements.overrideAttrs (old: {
        version = "14.13.0";
        src = prev.fetchurl {
          inherit (old.src) url;
          hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
        };
      });

      vscode-langservers-extracted = prev.vscode-langservers-extracted.overrideAttrs (oldAttrs: rec {
        version = "4.8.0";
        src = prev.fetchFromGitHub {
          owner = "hrsh7th";
          repo = "vscode-langservers-extracted";
          rev = "v${version}";
          sha256 = "sha256-sGnxmEQ0J74zNbhRpsgF/cYoXwn4jh9yBVjk6UiUdK0=";
        };
      });

      lib = prev.lib // {
        fetch7z =
          { url, sha256 }:
          let
            filename = baseNameOf url;
            pname = final.lib.strings.removeSuffix ".7z" filename;
            archive = prev.fetchurl { inherit url sha256; };
          in
          prev.runCommand pname
            {
              src = archive;
              nativeBuildInputs = [ prev.p7zip ];
              preferLocalBuild = true;
              allowSubstitutes = false;
            }
            ''
              mkdir -p $out
              7za x $src -o$out

              # strip top-level dir
              if [ "$(ls -A $out)" = "${pname}" ] || [ "$(ls -A $out)" = "GraphicsLib_1.12.1" ]; then
                mv $out/* $out/ 2>/dev/null || true
                rmdir $out/$(ls -A $out 2>/dev/null) 2>/dev/null || true
              fi
            '';
      };
    };
}
