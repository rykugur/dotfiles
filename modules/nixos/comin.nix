# Pull-based deployment: the host polls this repo and switches itself, so a
# push to the tracked branch is the deploy. Hosts that import this must never
# also be deployed by hand, or comin will fight the manual generation on its
# next poll.
{ inputs, ... }:
{
  flake.modules.nixos.comin =
    { config, lib, ... }:
    {
      imports = [ inputs.comin.nixosModules.comin ];

      options.ryk.comin.branch = lib.mkOption {
        type = lib.types.str;
        default = "master";
        description = ''
          Remote branch comin deploys from. A pilot host can track its own
          branch so iterating on it never touches master; flip the value back
          to "master" (and let the host converge on that commit) before the
          pilot branch is merged and stops moving.
        '';
      };

      options.ryk.comin.manualHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "jezrien"
          "taln"
        ];
        description = ''
          Hosts that are deployed by hand and must never poll. Importing this
          module on one of them would let a push overwrite a workstation's
          running generation, so it fails evaluation instead.
        '';
      };

      config.assertions = [
        {
          assertion = !(lib.elem config.networking.hostName config.ryk.comin.manualHosts);
          message = ''
            ${config.networking.hostName} is deployed by hand: remove
            `self.modules.nixos.comin` from its module list, or drop it from
            `ryk.comin.manualHosts` if it really should pull from git.
          '';
        }
      ];

      config.services.comin = {
        enable = true;

        remotes = [
          {
            name = "origin";
            # Public repo, so no deploy key or token is needed on the host.
            url = "https://github.com/rykugur/dotfiles.git";
            # `main` is comin's role name for the production branch, not a
            # branch named "main". The per-host testing branch keeps comin's
            # default name, `testing-<hostname>`, and runs as `test`.
            branches.main.name = config.ryk.comin.branch;
            poller.period = 60;
          }
        ];
      };
    };
}
