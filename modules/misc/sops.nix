{ inputs, ... }:
{
  flake.modules.homeManager.sops =
    { config, lib, pkgs, hostname, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      home.packages = with pkgs; [ age sops ];

      sops = {
        defaultSopsFile = ../hosts/${hostname}/secrets.yaml;
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

        # macOS has no XDG_RUNTIME_DIR, so the default %r/secrets.d mount point fails
        defaultSecretsMountPoint = lib.mkIf pkgs.stdenv.isDarwin "${config.home.homeDirectory}/.local/state/sops-nix/secrets.d";
        defaultSymlinkPath = lib.mkIf pkgs.stdenv.isDarwin "${config.home.homeDirectory}/.local/state/sops-nix/symlinks";
      };
    };
}
