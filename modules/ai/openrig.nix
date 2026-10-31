{ ... }:
{
  flake.modules.homeManager.openrig =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.openrig
        pkgs.tmux
      ];

      # Recursive linking (not a top-level symlink): OpenRig's instance-init
      # check lstats ~/.openrig/specs and requires a real directory, failing
      # with "expected directory, found other" on a plain symlinked source.
      # `recursive = true` mirrors the tree with real directories and only
      # symlinks the leaf files underneath.
      home.file.".openrig/specs" = {
        source = ../../configs/openrig/specs;
        recursive = true;
      };

      # OpenRig never starts tmux itself — it only probes the default socket
      # (`tmux list-sessions`) and blocks daemon start if no server answers
      # there. Keep one alive persistently so the default socket always exists.
      systemd.user.services.openrig-tmux-server = {
        Unit.Description = "Persistent default tmux server for OpenRig agent sessions";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.writeShellScript "openrig-tmux-keepalive-start" ''
            ${pkgs.tmux}/bin/tmux has-session -t openrig-keepalive 2>/dev/null \
              || ${pkgs.tmux}/bin/tmux new-session -d -s openrig-keepalive
          ''}";
          ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
