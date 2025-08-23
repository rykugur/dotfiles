{ config, inputs, outputs, hostname, username, ... }: {
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
      # workaround for obsidian
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };

  sops = {
    defaultSopsFile = ../hosts/${hostname}/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # also requires XDG_CONFIG_HOME to be set!
  xdg.enable = true;
}
