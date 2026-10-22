# Pull-based deployment: the host polls this repo and switches itself, so a
# push to master is the deploy. Hosts that import this must never also be
# deployed by hand, or comin will fight the manual generation on its next poll.
{ inputs, ... }:
{
  flake.modules.nixos.comin =
    { ... }:
    {
      imports = [ inputs.comin.nixosModules.comin ];

      services.comin = {
        enable = true;

        remotes = [
          {
            name = "origin";
            # Public repo, so no deploy key or token is needed on the host.
            url = "https://github.com/rykugur/dotfiles.git";
            # `main` here is comin's role name for the production branch, not a
            # branch named "main" — this repo's default branch is `master`.
            branches.main.name = "master";
            poller.period = 60;
          }
        ];
      };
    };
}
