{ ... }:
{
  flake.modules.homeManager.dolphin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      arkDesktop = [ "org.kde.ark.desktop" ];
      arkMimeTypes = [
        "application/arj"
        "application/gzip"
        "application/vnd.debian.binary-package"
        "application/vnd.efi.iso"
        "application/vnd.ms-cab-compressed"
        "application/vnd.rar"
        "application/x-7z-compressed"
        "application/x-archive"
        "application/x-arj"
        "application/x-bcpio"
        "application/x-bzip"
        "application/x-bzip-compressed-tar"
        "application/x-bzip2"
        "application/x-bzip2-compressed-tar"
        "application/x-cd-image"
        "application/x-compress"
        "application/x-compressed-tar"
        "application/x-cpio"
        "application/x-cpio-compressed"
        "application/x-deb"
        "application/x-iso9660-appimage"
        "application/x-java-archive"
        "application/x-lha"
        "application/x-lrzip"
        "application/x-lrzip-compressed-tar"
        "application/x-lz4"
        "application/x-lz4-compressed-tar"
        "application/x-lzip"
        "application/x-lzip-compressed-tar"
        "application/x-lzma"
        "application/x-lzma-compressed-tar"
        "application/x-lzop"
        "application/x-rpm"
        "application/x-source-rpm"
        "application/x-stuffit"
        "application/x-sv4cpio"
        "application/x-sv4crc"
        "application/x-tar"
        "application/x-tarz"
        "application/x-tzo"
        "application/x-xar"
        "application/x-xz"
        "application/x-xz-compressed-tar"
        "application/x-zstd-compressed-tar"
        "application/zip"
        "application/zlib"
        "application/zstd"
      ];
      dolphinWithStylix = pkgs.symlinkJoin {
        name = "dolphin-with-stylix";
        paths = [ pkgs.kdePackages.dolphin ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/dolphin" \
            --prefix XDG_CONFIG_DIRS : ${lib.escapeShellArg (lib.concatStringsSep ":" config.xdg.systemDirs.config)}
        '';
      };
    in
    {
      home.packages = with pkgs.kdePackages; [
        ark
        dolphinWithStylix
        dolphin-plugins
        ffmpegthumbs
        kdegraphics-thumbnailers
        kio-extras
        kio-fuse
      ];

      xdg = {
        enable = true;

        mimeApps = {
          enable = true;

          defaultApplications = {
            "inode/directory" = [ "org.kde.dolphin.desktop" ];
          }
          // lib.genAttrs arkMimeTypes (_: arkDesktop);
        };
      };
    };
}
