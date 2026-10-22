# hoid — always-on agent container (x86_64-linux, Proxmox LXC on roshar)
{
  config,
  inputs,
  self,
  ...
}:
let
  username = "dusty";
  hmModules = config.flake.modules.homeManager;
in
{
  imports = [ ./_image.nix ];

  flake.nixosConfigurations.hoid = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.nix-defaults
      self.modules.nixos.meta
      self.modules.nixos.login-shell
      self.modules.nixos.vasher-cache
      self.modules.nixos.helix-root
      self.modules.nixos.omp-host

      ./_platform-lxc.nix
      ./_role.nix

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "bak";
          extraSpecialArgs = {
            inherit inputs username;
            outputs = inputs.self;
            hostname = "hoid";
          };

          users.${username} = {
            # `login-shell` already imports the shared `shell` module for this
            # user (nushell + fish companion).
            imports = with hmModules; [
              helix
              helix-lxc
              git
              starship
              zoxide
              direnv
              bat
              carapace
              atuin
              tmux
              oh-my-pi
            ];

            # The shared `nushell` module sources `~/.dotfiles/configs/nu`,
            # which on a workstation is a symlink into the checkout. Hoid has
            # no checkout, so point that path at the flake's own copy;
            # `config.nu` sources its siblings relatively, so the whole
            # directory has to be there.
            home.file.".dotfiles/configs/nu".source = ../../../configs/nu;

            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          };

          # helix-root gives root the shared Helix config; it needs the same
          # headless clipboard override as the primary user.
          users.root.imports = [ hmModules.helix-lxc ];
        };
      }
    ];
    specialArgs = {
      inherit inputs username;
      outputs = inputs.self;
      hostname = "hoid";
    };
  };
}
