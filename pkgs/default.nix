# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{
  pkgs ? import <nixpkgs> { },
  inputs ? { },
  ...
}:
let
  suiVersion = "1.72.2";
  sptSrc = inputs.spt or null;
in
{
  ### gaming
  # star citizen
  opentrack = pkgs.callPackage ./opentrack.nix { };
  opentrack-StarCitizen = pkgs.callPackage ./opentrack-StarCitizen.nix { };
  # misc
  jackify = pkgs.callPackage ./jackify.nix { };
  eve-wrench = pkgs.callPackage ./eve-wrench.nix { };
  rift-intel-tool = pkgs.callPackage ./rift-intel-tool.nix { };

  ### misc
  rackpeek = pkgs.callPackage ./rackpeek.nix { };
  tpm = pkgs.callPackage ./tpm.nix { };

  ### sui/move (eve frontier)
  sui = pkgs.callPackage ./sui.nix { version = suiVersion; };
  prettier-plugin-move = pkgs.callPackage ./prettier-plugin-move.nix { };

  ### sptarkov (from SPT-Linux-Guide input scripts, wrapped for nix)
  # These provide spt-additions (installer), spt-server (native server runner),
  # spt-launcher (umu-wrapped client launcher) in PATH when the spt hm module is used.
} // (if sptSrc != null then (
  let
    lib = pkgs.lib;
    # Common runtime deps expected by the additions script (plus helpers).
    # Guarded lookups so this evals on all systems (e.g. darwin perSystem + nixos check);
    # missing tools are simply not in PATH for the wrapper (script will download fallbacks).
    sptRuntimeDeps =
      let p = pkgs; in
      [ p.bash p.coreutils p.curl p.jq p.python3 p.which p.file ]
      ++ lib.optional (p ? p7zip) p.p7zip
      ++ lib.optional (p ? _7zz) p._7zz
      ++ lib.optional (p ? umu-launcher) p.umu-launcher
      ++ lib.optional (p ? steam-run) p.steam-run
      ++ lib.optional (p ? winetricks) p.winetricks
      ++ lib.optional (p ? cabextract) p.cabextract
      ++ lib.optional (p ? unixtools && p.unixtools ? xxd) p.unixtools.xxd;

    # The script hard-requires `7zzs`; provide if p7zip present (else script falls back to download).
    spt7zzs =
      if pkgs ? p7zip then
        pkgs.runCommand "7zzs" { } ''
          mkdir -p $out/bin
          ln -s ${lib.getExe pkgs.p7zip} $out/bin/7zzs
          ln -s ${lib.getExe pkgs.p7zip} $out/bin/7zz
        ''
      else null;

    mkSptTool = name: srcPath: description:
      pkgs.stdenv.mkDerivation {
        pname = name;
        version = "unstable-2025-06"; # pinned via flake input
        src = sptSrc;
        dontBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          install -D -m755 $src/${srcPath} $out/bin/${name}
          wrapProgram $out/bin/${name} \
            --prefix PATH : ${lib.makeBinPath (builtins.filter (x: x != null) (sptRuntimeDeps ++ [ spt7zzs ]))}
        '';
        meta = {
          inherit description;
          homepage = "https://github.com/rykugur/SPT-Linux-Guide";
          platforms = [ "x86_64-linux" "aarch64-linux" ];
        };
      };

  in
  {
    spt-additions = mkSptTool "spt-additions" "scripts/spt-additions" "SPT additions CLI installer & manager script (from SPT-Linux-Guide)";

    # Convenience runner for the native Linux SPT server.
    # Looks for install at $SPT_DIR (default ~/Games/SPTarkov), cds and execs the .Linux binary.
    # (The guide's launch-server.sh is desktop-shortcut oriented and picks a terminal; this one
    # runs in the current shell so `spt-server` "just works" from terminal.)
    spt-server =
      let
        drv = pkgs.writeShellScriptBin "spt-server" ''
          set -euo pipefail
          SPT_DIR="''${SPT_DIR:-$HOME/Games/SPTarkov}"
          SERVER_BIN="$SPT_DIR/SPT/SPT.Server.Linux"
          if [ ! -x "$SERVER_BIN" ]; then
            echo "SPT server binary not found at $SERVER_BIN" >&2
            echo "Run 'spt-additions install' (or equivalent) first to populate ~/Games/SPTarkov." >&2
            exit 1
          fi
          echo "Starting SPT Server (native Linux) from $SPT_DIR ..."
          cd "$SPT_DIR/SPT"
          exec "$SERVER_BIN" "$@"
        '';
      in
      drv.overrideAttrs (old: {
        meta = (old.meta or { }) // {
          platforms = [ "x86_64-linux" "aarch64-linux" ];
          description = "SPTarkov native Linux server runner (for use with the spt home-manager module)";
          homepage = "https://github.com/rykugur/SPT-Linux-Guide";
        };
      });

    # Convenience: run the SPT launcher exe (windows) under umu-run (proton).
    # Assumes prefix + files populated by prior spt-additions run.
    spt-launcher =
      let
        drv = pkgs.writeShellScriptBin "spt-launcher" ''
          set -euo pipefail
          SPT_DIR="''${SPT_DIR:-$HOME/Games/SPTarkov}"
          LAUNCHER="$SPT_DIR/SPT.Launcher.exe"
          if [ ! -f "$LAUNCHER" ]; then
            LAUNCHER="$SPT_DIR/SPT/SPT.Launcher.exe"
          fi
          if [ ! -f "$LAUNCHER" ]; then
            echo "SPT launcher not found at expected paths under $SPT_DIR" >&2
            echo "Run 'spt-additions install' first." >&2
            exit 1
          fi
          echo "Launching SPT via umu-run from $SPT_DIR ..."
          exec ${if pkgs ? umu-launcher then "${pkgs.umu-launcher}/bin/umu-run" else "umu-run"} "$LAUNCHER" "$@"
        '';
      in
      drv.overrideAttrs (old: {
        meta = (old.meta or { }) // {
          platforms = [ "x86_64-linux" "aarch64-linux" ];
          description = "SPTarkov launcher (umu/proton wrapper, for use with the spt home-manager module)";
          homepage = "https://github.com/rykugur/SPT-Linux-Guide";
        };
      });
  }
) else {})
