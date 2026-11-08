{ ... }:
{
  flake.modules.nixos.logitech =
    { pkgs, ... }:
    {
      services.ratbagd = {
        enable = true;
        # nixpkgs' libratbag 0.18 lacks G502 X Plus support. Remove this
        # override once the packaged release includes its device and quirks.
        package = pkgs.libratbag.overrideAttrs {
          version = "0.18-unstable-2026-09-17";
          src = pkgs.fetchFromGitHub {
            owner = "libratbag";
            repo = "libratbag";
            rev = "8235b5bb6032dea15901ab58a8218956f4494d08";
            hash = "sha256-0uRBbVI5GrXyUUvDlpa2w5djyRWMbl6rzpdOWR2TkPg=";
          };
        };
      };

      environment.systemPackages = [ pkgs.piper ];
    };
}
