{ config, inputs, pkgs, hostname, username, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];


  sops = {
    defaultSopsFile = ../modules/hosts/${hostname}/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  home = let homePath = if pkgs.stdenv.isDarwin then "/Users" else "/home";
  in {
    inherit username;
    homeDirectory = "${homePath}/${username}";
  };

  # also requires XDG_CONFIG_HOME to be set!
  xdg.enable = true;
}
