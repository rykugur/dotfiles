{ inputs, pkgs, ... }: {

  default =
    pkgs.mkShell { packages = [ pkgs.just pkgs.sops pkgs.nixos-anywhere ]; };

  lua = pkgs.mkShell {
    packages = [
      inputs.luarocks-nix.packages.${pkgs.system}.default
      pkgs.love
      pkgs.lua
      pkgs.nurl
    ];

    shellHook = ''
      eval $(luarocks path --bin)
      fish
      exit
    '';
  };

  kubes = pkgs.mkShell {
    buildInputs = with pkgs; [
      k9s
      kubectl
      kubectx
      kubecolor

      kubernetes-helm
      helmfile

      docker
      minikube
    ];
  };
}
