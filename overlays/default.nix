{ ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
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
    vscode-langservers-extracted =
      prev.vscode-langservers-extracted.overrideAttrs (oldAttrs: rec {
        version = "4.8.0";
        src = prev.fetchFromGitHub {
          owner = "hrsh7th";
          repo = "vscode-langservers-extracted";
          rev = "v${version}";
          sha256 = "sha256-sGnxmEQ0J74zNbhRpsgF/cYoXwn4jh9yBVjk6UiUdK0=";
        };
      });

    lib = prev.lib // {
      fetch7zip = { url, sha256 }:
        let
          filename = builtins.baseNameOf url;
          pname = final.lib.strings.removeSuffix ".7z" filename;
        in prev.stdenv.mkDerivation {
          name = pname;
          inherit pname;
          src = builtins.fetchurl { inherit url sha256; };

          buildInputs = [ prev.p7zip ];

          preferLocalBuild = true;
          buildCommand = ''
            mkdir -p $out
            7za x $src -o$out
          '';
        };
    };
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    # example patch:
    # super-slicer = prev.super-slicer.overrideAttrs (o: {
    #   patches = (o.patches or [ ]) ++ [
    #     # can be removed once https://github.com/NixOS/nixpkgs/pull/298652 is merged
    #     ./patches/super-slicer.patch
    #   ];
    # });
  };
}
