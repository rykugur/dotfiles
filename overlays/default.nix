{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    hyprprop = inputs.hyprland-contrib.packages.${prev.system}.hyprprop;
    hyprland-qtutils =
      inputs.hyprland-qtutils.packages."${prev.system}".default;

    catppuccin-ports = {
      atuin = prev.fetchFromGitHub {
        owner = "catppuccin";
        repo = "atuin";
        rev = "abfab12de743aa73cf20ac3fa61e450c4d96380c";
        sha256 = "sha256-t/Pq+hlCcdSigtk5uzw3n7p5ey0oH/D5S8GO/0wlpKA=";
      };
      btop = prev.fetchgit {
        url = "https://github.com/catppuccin/btop";
        rev = "f437574b600f1c6d932627050b15ff5153b58fa3";
        sha256 = "sha256-mEGZwScVPWGu+Vbtddc/sJ+mNdD2kKienGZVUcTSl+c=";
      };
      hyprland = prev.fetchgit {
        url = "https://github.com/catppuccin/hyprland";
        rev = "v1.3";
        sha256 = "sha256-jkk021LLjCLpWOaInzO4Klg6UOR4Sh5IcKdUxIn7Dis=";
      };
      yazi = prev.fetchFromGitHub {
        owner = "catppuccin";
        repo = "yazi";
        rev = "5d3a1eecc304524e995fe5b936b8e25f014953e8";
        hash = "sha256-UVcPdQFwgBxR6n3/1zRd9ZEkYADkB5nkuom5SxzPTzk=";
      };
    };

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
