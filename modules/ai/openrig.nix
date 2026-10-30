{ ... }:
{
  flake.modules.homeManager.openrig =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.openrig ];

      # The scanner follows a library-root symlink, but skips nested symlinks.
      home.file.".openrig/specs".source = ../../configs/openrig/specs;
    };
}
