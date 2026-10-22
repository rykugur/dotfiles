{ self, ... }:
{
  flake.modules.nixos.login-shell =
    { config, pkgs, username, ... }:
    {
      users.users.${config.ryk.username}.shell = pkgs.nushell;
      environment.shells = [ pkgs.nushell ];
      home-manager.users.${username}.imports = [ self.modules.homeManager.shell ];
    };
}
