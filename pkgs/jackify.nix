{
  appimageTools,
  fetchurl,
  ...
}:
appimageTools.wrapType2 rec {
  pname = "jackify";
  version = "v0.2.1.1";
  # pkgs.fetchurl, not builtins.fetchurl: the builtin downloads during
  # evaluation and never becomes a derivation, so it is invisible to
  # `nix derivation show` and to scripts/rehash.sh.
  src = fetchurl {
    url = "https://github.com/Omni-guides/Jackify/releases/download/${version}/Jackify.AppImage";
    hash = "sha256-zVreomYaYfOU6pEUlZz+rVMjeuTZBKzylUMF1ComEdQ=";
  };

  extraPkgs =
    pkgs: with pkgs; [
      python3
      zstd
    ];

  meta = {
    homepage = "https://github.com/Omni-guides/Jackify";
    description = "A modlist installation and configuration tool for Wabbajack modlists on Linux";
    platforms = [ "x86_64-linux" ];
  };
}
