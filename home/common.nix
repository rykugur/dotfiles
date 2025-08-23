{ config, inputs, outputs, pkgs, hostname, username, ... }: {
  imports = [
    outputs.hmModules

    inputs.sops-nix.homeManagerModules.sops
  ];

  nixpkgs = {
    overlays = [ outputs.overlays.additions outputs.overlays.modifications ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  sops = {
    defaultSopsFile = ../hosts/${hostname}/secrets.yaml;
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
