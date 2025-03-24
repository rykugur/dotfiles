# This file defines overlays
{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # patool = prev.patool.overrideAttrs (old: {
    #   doCheck = false;
    #   doInstallCheck = false;
    #   pytestCheckPhase = false;
    # });
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

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  # unstable-packages = final: _prev: {
  #   unstable = import inputs.nixpkgs-unstable {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
}
