{ ... }:
{
  # Always-on OMP agent host. Two independent surfaces, both optional:
  #
  # * `web` runs ompweb (github:kahme247/ompweb), a local browser UI that
  #   drives omp over RPC on this machine and reads its sessions directly.
  #   Nothing leaves the LAN.
  # * `session` runs one supervised interactive OMP session under a dtach
  #   master, so systemd owns a real foreground process, the session gets the
  #   pty `collab.autoStart` requires, and `ttyd` can attach to that same
  #   session. Collab is relay-mediated: the room and its browser client live
  #   on `collab.relayUrl` / `collab.webUrl`, so it reaches you anywhere but
  #   it is a third-party hop.
  #
  # Services bind loopback by default; `openFirewall` and the per-service
  # address options are how a host opts into LAN exposure. A Collab control
  # URL grants full agent control, so the link endpoint is as sensitive as
  # the terminal.
  flake.modules.nixos.omp-host =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.ompHost;

      # Single source for the binary: the Home Manager module already pins it
      # for this user. No second flake reference to drift.
      ompPackage = config.home-manager.users.${cfg.user}.programs.omp.package;
      omp = lib.getExe' ompPackage "omp";

      userCfg = config.users.users.${cfg.user};
      home = userCfg.home;
      group = userCfg.group;

      dtach = lib.getExe pkgs.dtach;

      # Caddy enables ACME for an `https://` site address and serves plain
      # HTTP for an `http://` one.
      scheme = if cfg.proxy.tls.enable then "https" else "http";
      socket = "/run/omp/agent.sock";

      # Passed with --config, never written over ~/.omp/agent/config.yml: that
      # file holds oauth and onboarding state the agent writes itself.
      overlay = (pkgs.formats.yaml { }).generate "omp-host.yml" {
        collab = {
          autoStart = "control";
          displayName = cfg.displayName;
        };
        tools.approvalMode = cfg.approvalMode;
        startup = {
          quiet = true;
          # A fresh config dir otherwise opens the 5-step setup wizard, and
          # Collab refuses guest prompts until the host finishes starting up —
          # so an unattended container would sit there unusable.
          setupWizard = false;
          checkUpdate = false;
        };
      };

      agentCommand = lib.escapeShellArgs (
        [
          omp
          "--config"
          "${overlay}"
          "--cwd"
          cfg.workdir
        ]
        ++ cfg.extraArgs
      );

      linkDispenser = pkgs.writers.writePython3Bin "omp-collab-link" { flakeIgnore = [ "E501" ]; } ''
        # Resolves the agent's current Collab control URL on demand. The room
        # generation changes on /new, /resume and /fork, and `collab link`
        # refuses a stale generation, so every request re-lists.
        import json
        import subprocess
        import sys
        from http.server import BaseHTTPRequestHandler, HTTPServer

        OMP = "${omp}"
        HOST = "${cfg.linkService.address}"
        PORT = ${toString cfg.linkService.port}


        def run(args):
            proc = subprocess.run(
                [OMP] + args, capture_output=True, text=True, timeout=20, check=True
            )
            return json.loads(proc.stdout)


        def resolve():
            hosts = run(["collab", "list", "--json"]).get("hosts", [])
            live = [h for h in hosts if h.get("access") == "control" and h.get("relayConnected")]
            if not live:
                raise RuntimeError("no Collab room with control access is published")
            live.sort(key=lambda h: h.get("startedAt") or 0)
            host = live[-1]
            link = run(["collab", "link", host["instanceId"], "--json"])
            return link["url"], host


        def resolve_with_retry():
            # A session switch between list and link invalidates the generation.
            try:
                return resolve()
            except subprocess.CalledProcessError:
                return resolve()


        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                try:
                    url, host = resolve_with_retry()
                except Exception as exc:
                    body = str(exc).encode()
                    self.send_response(503)
                    self.send_header("Content-Type", "text/plain; charset=utf-8")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)
                    return
                if self.path.startswith("/json"):
                    payload = json.dumps(
                        {
                            "url": url,
                            "sessionId": host.get("sessionId"),
                            "generation": host.get("generation"),
                            "busy": host.get("busy"),
                            "cwd": host.get("cwd"),
                        }
                    ).encode()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Content-Length", str(len(payload)))
                    self.send_header("Cache-Control", "no-store")
                    self.end_headers()
                    self.wfile.write(payload)
                    return
                self.send_response(302)
                self.send_header("Location", url)
                self.send_header("Cache-Control", "no-store")
                self.send_header("Content-Length", "0")
                self.end_headers()

            def log_message(self, fmt, *args):
                sys.stderr.write("omp-collab-link: " + (fmt % args) + "\n")


        if __name__ == "__main__":
            HTTPServer((HOST, PORT), Handler).serve_forever()
      '';
    in
    {
      options.ryk.ompHost = {
        enable = lib.mkEnableOption "the OMP agent host";

        web = {
          enable = lib.mkEnableOption "ompweb, the local browser UI for omp" // {
            default = true;
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.ompweb;
            defaultText = lib.literalExpression "pkgs.ompweb";
          };
          address = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Bind address. Keep it on loopback and put a reverse proxy in front: ompweb has no TLS of its own.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 30177;
          };
          passwordHashFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              File holding an `ompweb hash-password` scrypt hash, loaded as
              `OMP_WEB_PASSWORD_HASH`. Null disables the login entirely, which
              ompweb only permits on a loopback bind — so whatever can reach
              the proxy gets the agent.
            '';
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "omp web";
            description = "Name shown in browser tabs and installed PWAs (`OMP_WEB_NAME`).";
          };
        };

        session = {
          enable = lib.mkEnableOption "the supervised dtach-hosted OMP session (and with it Collab)" // {
            default = true;
          };
        };

        proxy = {
          enable = lib.mkEnableOption "a Caddy front end for the web UI and the broker";
          hostName = lib.mkOption {
            type = lib.types.str;
            default = "${config.networking.hostName}.local.ryk.sh";
            description = "Name the proxy serves, and the name on its certificate.";
          };
          tls = {
            enable = lib.mkEnableOption "ACME certificates through a DNS-01 challenge" // {
              default = true;
            };
            email = lib.mkOption {
              type = lib.types.str;
              default = "ryk@ryk.sh";
            };
            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Environment file holding `CF_API_TOKEN` for the DNS-01
                challenge. Required when `tls.enable` is set: these names only
                exist on the LAN, so HTTP-01 could never validate them.
              '';
            };
          };
          brokerPort = lib.mkOption {
            type = lib.types.port;
            default = 8765;
            description = ''
              Port the proxy publishes the broker on. Clients keep
              `https://<host>:<port>` as their `auth.broker.url`, so the
              broker moves to a loopback port behind the proxy rather than
              living under a path prefix clients would have to know about.
            '';
          };
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = config.ryk.username;
          description = "User that owns the session, its Collab room, and the credential store.";
        };

        workdir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/omp-agent";
          description = "Working directory the agent starts in. Not the user's home: OMP relocates sessions started in ~.";
        };

        displayName = lib.mkOption {
          type = lib.types.str;
          default = config.networking.hostName;
          description = "Name shown to Collab participants.";
        };

        approvalMode = lib.mkOption {
          type = lib.types.enum [
            "always-ask"
            "write"
            "yolo"
          ];
          default = "write";
          description = ''
            Approval tier that prompts. `write` auto-approves reads and
            workspace writes and prompts for every exec (bash, eval, task).
            Prompts are answerable from a Collab guest, so this stays usable
            from a phone.
          '';
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "--add-dir"
            "/var/lib/omp-agent/infra"
          ];
          description = "Extra arguments appended to the supervised omp invocation.";
        };

        ttyd = {
          enable = lib.mkEnableOption "a browser terminal attached to the agent session" // {
            default = true;
          };
          interface = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "lo";
            description = "Interface ttyd listens on. Null listens on every interface.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 7681;
          };
          passwordFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Basic-auth password file for ttyd. Without it the only gate is whatever can reach the bind address.";
          };
        };

        linkService = {
          enable = lib.mkEnableOption "the Collab link dispenser" // {
            default = true;
          };
          address = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address the dispenser binds. It hands out Collab control URLs, so treat reachability as authorization.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 7682;
          };
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Open the ttyd, dispenser, and broker ports. Only meaningful once they bind something other than loopback.";
        };

        broker = {
          enable = lib.mkEnableOption "the OMP auth-broker credential vault";
          bind = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1:8765";
            description = "Broker listen address. Keep it on loopback or a tailnet address; the broker has no transport security of its own.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.tmpfiles.rules = lib.mkIf cfg.session.enable [
          "d ${cfg.workdir} 0750 ${cfg.user} ${group} -"
        ];

        systemd.services.ompweb = lib.mkIf cfg.web.enable {
          description = "ompweb — local browser UI for the OMP agent";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          # ompweb spawns `omp`, which shells out constantly.
          path = with pkgs; [
            bashInteractive
            coreutils
            git
            gnutar
            gzip
            openssh
            ompPackage
          ];
          environment = {
            HOME = home;
            PORT = toString cfg.web.port;
            OMP_WEB_HOSTNAME = cfg.web.address;
            OMP_WEB_OMP_BIN = omp;
            OMP_WEB_NAME = cfg.web.name;
            OMP_WEB_NO_OPEN = "1";
            # Updates come from the flake, not from the running service.
            OMP_WEB_DISABLE_AUTOUPDATE = "1";
          };
          serviceConfig = {
            User = cfg.user;
            Group = group;
            WorkingDirectory = home;
            ExecStart =
              if cfg.web.passwordHashFile == null then
                lib.getExe cfg.web.package
              else
                # The hash is read through a systemd credential so the sops
                # file itself never has to be readable by this user. A scrypt
                # hash in the environment is what ompweb documents; only the
                # plaintext password must never get there, because every omp
                # session ompweb spawns inherits its environment.
                pkgs.writeShellScript "ompweb-start" ''
                  export OMP_WEB_PASSWORD_HASH="$(cat "$CREDENTIALS_DIRECTORY/password-hash")"
                  exec ${lib.getExe cfg.web.package}
                '';
            Restart = "always";
            RestartSec = 5;
          }
          // lib.optionalAttrs (cfg.web.passwordHashFile != null) {
            LoadCredential = "password-hash:${cfg.web.passwordHashFile}";
          };
        };

        assertions = [
          {
            assertion = !(cfg.proxy.enable && cfg.proxy.tls.enable) || cfg.proxy.tls.environmentFile != null;
            message = "ryk.ompHost.proxy.tls needs an environmentFile holding CF_API_TOKEN.";
          }
        ];

        services.caddy = lib.mkIf cfg.proxy.enable {
          enable = true;
          # The Cloudflare DNS plugin is not in the stock build, and DNS-01 is
          # the only challenge that can answer for a name that resolves on the
          # LAN only.
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
            hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
          };
          email = lib.mkIf cfg.proxy.tls.enable cfg.proxy.tls.email;
          environmentFile = lib.mkIf (cfg.proxy.tls.environmentFile != null) cfg.proxy.tls.environmentFile;
          globalConfig = lib.mkIf cfg.proxy.tls.enable ''
            acme_dns cloudflare {env.CF_API_TOKEN}
          '';
          virtualHosts = lib.mkMerge [
            (lib.mkIf cfg.web.enable {
              "${scheme}://${cfg.proxy.hostName}".extraConfig = ''
                reverse_proxy ${cfg.web.address}:${toString cfg.web.port}
              '';
            })
            (lib.mkIf cfg.broker.enable {
              "${scheme}://${cfg.proxy.hostName}:${toString cfg.proxy.brokerPort}".extraConfig = ''
                reverse_proxy ${cfg.broker.bind}
              '';
            })
          ];
        };

        systemd.services.omp-agent = lib.mkIf cfg.session.enable {
          description = "Always-on OMP agent session";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          # The agent shells out constantly; give it a usable PATH.
          path = with pkgs; [
            bashInteractive
            coreutils
            git
            gnutar
            gzip
            openssh
          ];
          environment = {
            HOME = home;
            TERM = "xterm-256color";
          };
          serviceConfig = {
            User = cfg.user;
            Group = group;
            WorkingDirectory = cfg.workdir;
            RuntimeDirectory = "omp";
            RuntimeDirectoryMode = "0700";
            # -N keeps the dtach master in the foreground so systemd supervises
            # the real process; attachers come and go over the socket.
            ExecStart = "${dtach} -N ${socket} ${pkgs.runtimeShell} -c ${lib.escapeShellArg agentCommand}";
            Restart = "always";
            RestartSec = 5;
          };
        };

        services.ttyd = lib.mkIf cfg.ttyd.enable {
          enable = true;
          user = cfg.user;
          interface = lib.mkIf (cfg.ttyd.interface != null) cfg.ttyd.interface;
          port = cfg.ttyd.port;
          writeable = true;
          entrypoint = [
            dtach
            "-a"
            socket
            "-r"
            "winch"
          ];
          username = lib.mkIf (cfg.ttyd.passwordFile != null) cfg.user;
          passwordFile = lib.mkIf (cfg.ttyd.passwordFile != null) cfg.ttyd.passwordFile;
        };

        systemd.services.omp-collab-link = lib.mkIf cfg.linkService.enable {
          description = "Dispense the agent's current Collab control URL";
          wantedBy = [ "multi-user.target" ];
          after = [ "omp-agent.service" ];
          environment.HOME = home;
          serviceConfig = {
            User = cfg.user;
            Group = group;
            ExecStart = lib.getExe linkDispenser;
            Restart = "always";
            RestartSec = 5;
          };
        };

        systemd.services.omp-auth-broker = lib.mkIf cfg.broker.enable {
          description = "OMP auth-broker credential vault";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          environment.HOME = home;
          serviceConfig = {
            User = cfg.user;
            Group = group;
            ExecStart = "${omp} auth-broker serve --bind ${cfg.broker.bind}";
            Restart = "always";
            RestartSec = 5;
          };
        };

        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall (
          if cfg.proxy.enable then
            # Only the proxy is reachable; everything it fronts stays on
            # loopback. 80 stays open for Caddy's HTTP->HTTPS redirect.
            [ 80 ]
            ++ lib.optional cfg.proxy.tls.enable 443
            ++ lib.optional cfg.broker.enable cfg.proxy.brokerPort
          else
            lib.optional cfg.ttyd.enable cfg.ttyd.port
            ++ lib.optional cfg.linkService.enable cfg.linkService.port
            ++ lib.optional cfg.broker.enable (lib.toInt (lib.last (lib.splitString ":" cfg.broker.bind)))
        );

        environment.systemPackages = [
          ompPackage
          pkgs.dtach
        ]
        ++ lib.optional cfg.linkService.enable linkDispenser;
      };
    };
}
