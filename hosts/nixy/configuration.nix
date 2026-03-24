{ hostname, inputs, lib, outputs, modulesPath, username, ... }: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")

    inputs.home-manager.nixosModules.home-manager

    # TODO: can't use outputs.modules.nixos.ssh yet because the dendritic ssh
    # module bundles HM sops/ssh which requires secrets.yaml (nixy has none)
    ../../legacy-modules/nixos/ssh.nix
  ];

  ryk.ssh.enable = true;

  nix.settings = { sandbox = false; };

  proxmoxLXC = {
    manageNetwork = false;
    privileged = true;
  };

  security.pam.services.sshd.allowNullPassword = true;

  services.fstrim.enable = false; # Let Proxmox host handle fstrim

  users.users = {
    ${username} = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/${username}";
      extraGroups = [ "wheel" ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "25.05";
}
