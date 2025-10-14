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
      bat = prev.fetchgit {
        url = "https://github.com/catppuccin/bat";
        rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
        sha256 = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
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
      hyprlock = prev.fetchgit {
        url = "https://github.com/catppuccin/hyprlock";
        rev = "f650895064ae80db7c0e095829fce83fd85d0b26";
        sha256 = "sha256-kgVlPaWeaH/p0qGc1+Lj2H6YlDAk5CemNo1FFF8ymZ8=";
      };
      waybar = prev.fetchgit {
        url = "https://github.com/catppuccin/waybar";
        rev = "ee8ed32b4f63e9c417249c109818dcc05a2e25da";
        sha256 = "sha256-za0y6hcN2rvN6Xjf31xLRe4PP0YyHu2i454ZPjr+lWA=";
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
      fetch7z = { url, sha256 }:
        let
          filename = builtins.baseNameOf url;
          pname = final.lib.strings.removeSuffix ".7z" filename;
          archive = prev.fetchurl { inherit url sha256; };
        in prev.runCommand pname {
          src = archive;
          nativeBuildInputs = [ prev.p7zip ];
          preferLocalBuild = true;
          allowSubstitutes = false;
          # outputHashMode = "recursive";
          # outputHashAlgo = "sha256";
        } ''
          mkdir -p $out
          7za x $src -o$out

          # strip top-level dir
          if [ "$(ls -A $out)" = "${pname}" ] || [ "$(ls -A $out)" = "GraphicsLib_1.12.1" ]; then  # Adjust if needed
            mv $out/* $out/ 2>/dev/null || true
            rmdir $out/$(ls -A $out 2>/dev/null) 2>/dev/null || true
          fi          
        '';
    };
  };
}
