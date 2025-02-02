{ inputs, pkgs, ... }: {

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
