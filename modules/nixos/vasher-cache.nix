{ ... }:
let
  publicKey = builtins.readFile ../hosts/vasher/cache-signing-key.pub;
in
{
  flake.modules.nixos.vasher-cache =
    { config, lib, ... }:
    let
      cfg = config.ryk.vasherCache;
    in
    {
      options.ryk.vasherCache = {
        enable = lib.mkEnableOption "the Vasher LAN binary cache";
        url = lib.mkOption {
          type = lib.types.str;
          default = "http://vasher.local.ryk.sh:5000/";
        };
        serve = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      config = lib.mkIf cfg.enable (lib.mkMerge [
        {
          nix.settings = {
            substituters = [ cfg.url ];
            trusted-public-keys = [ publicKey ];
          };
        }
        (lib.mkIf cfg.serve {
          sops.secrets.vasher_ssh_host_ed25519_key = {
            key = "ssh_host_ed25519_key";
            owner = "root";
            group = "root";
            mode = "0600";
          };
          sops.secrets.vasher_harmonia_signing_key = {
            key = "swoleflake/harmonia_signing_key";
            owner = "harmonia";
            group = "harmonia";
            mode = "0400";
          };
          services.openssh.hostKeys = [
            {
              path = config.sops.secrets.vasher_ssh_host_ed25519_key.path;
              type = "ed25519";
            }
          ];
          services.harmonia.cache = {
            enable = true;
            signKeyPaths = [ config.sops.secrets.vasher_harmonia_signing_key.path ];
            settings = {
              bind = "[::]:5000";
              priority = 30;
            };
          };
          networking.firewall.interfaces.eth0.allowedTCPPorts = [ 5000 ];
        })
      ]);
    };
}
