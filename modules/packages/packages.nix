{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        jackify = pkgs.appimageTools.wrapType2 rec {
          pname = "jackify";
          version = "v0.2.1.1";
          src = builtins.fetchurl {
            url = "https://github.com/Omni-guides/Jackify/releases/download/${version}/Jackify.AppImage";
            sha256 = "sha256:1m0i4qmd81a3jpraq16rwix26lxdzsf9a54ixaag6q8scsidwnnd";
          };

          extraPkgs =
            pkgs: with pkgs; [
              python3
              zstd
            ];

          meta = {
            homepage = "https://github.com/Omni-guides/Jackify";
            description = "A modlist installation and configuration tool for Wabbajack modlists on Linux";
          };
        };
      };
    };
}
