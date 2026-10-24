# Declarative Incus guests, in Nix, reconciled by the host itself.
#
# Incus's own preseed cannot do this: `InitLocalPreseed` carries networks,
# storage pools, storage volumes, profiles, projects, certificates and cluster
# groups — never instances. The alternative, an OpenTofu provider, would need
# someone to run `tofu apply` from a workstation with state and credentials,
# which breaks the comin pull loop. A host that talks to its own Incus socket
# needs no credential and converges from a push like everything else.
{ ... }:
{
  flake.modules.nixos.incus-instances =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.incus;
      incus = lib.getExe config.virtualisation.incus.clientPackage;

      instanceModule = {
          options = {
            ensure = lib.mkOption {
              type = lib.types.enum [
                "present"
                "absent"
              ];
              default = "present";
              description = ''
                `absent` deletes the instance, data and all. Deletion is
                deliberately explicit: dropping an attribute from
                `ryk.incus.instances` leaves the guest alone, because a bad
                rebase must never destroy a VM.
              '';
            };

            image = lib.mkOption {
              type = lib.types.str;
              example = "images:debian/12";
              description = "Image to create from. Only read at creation time.";
            };

            virtualMachine = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Create a VM rather than a system container.";
            };

            profiles = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "default" ];
            };

            config = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              example = {
                "limits.cpu" = "3";
                "limits.memory" = "6GiB";
              };
            };

            devices = lib.mkOption {
              type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
              default = { };
              example = {
                root = {
                  type = "disk";
                  path = "/";
                  pool = "local";
                };
              };
            };

            running = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether the instance should be running after a reconcile.";
            };
          };
        };

      # One PATCH per instance. PATCH merges server-side, so volatile keys
      # (MAC addresses, last power state) survive; a PUT would drop them.
      # The same merge is why removing a single config key here does not
      # remove it from the guest — only whole instances have a delete path.
      patchBody =
        instance:
        builtins.toJSON {
          inherit (instance) config devices profiles;
        };

      present = name: instance: ''
        if ${incus} info ${name} >/dev/null 2>&1; then
          echo "incus-instances: ${name} exists"
        else
          echo "incus-instances: creating ${name}"
          ${incus} create ${instance.image} ${name} \
            ${lib.optionalString instance.virtualMachine "--vm"} \
            ${lib.concatMapStringsSep " " (p: "--profile ${p}") instance.profiles}
        fi

        ${incus} query -X PATCH -d ${lib.escapeShellArg (patchBody instance)} /1.0/instances/${name} >/dev/null

        state="$(${incus} list name="^${name}$" --format=csv --columns=s)"
        ${
          if instance.running then
            ''
              if [ "$state" != "RUNNING" ]; then
                echo "incus-instances: starting ${name}"
                ${incus} start ${name}
              fi
            ''
          else
            ''
              if [ "$state" = "RUNNING" ]; then
                echo "incus-instances: stopping ${name}"
                ${incus} stop ${name}
              fi
            ''
        }
      '';

      absent = name: ''
        if ${incus} info ${name} >/dev/null 2>&1; then
          echo "incus-instances: deleting ${name}"
          ${incus} delete --force ${name}
        fi
      '';

      reconcile = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: instance: if instance.ensure == "present" then present name instance else absent name
        ) cfg.instances
      );
    in
    {
      options.ryk.incus.instances = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule instanceModule);
        default = { };
        description = ''
          Incus guests this host owns. Reconciled by `incus-instances.service`
          on every activation, so a push that comin deploys is what changes a
          guest.
        '';
      };

      config = lib.mkIf (cfg.instances != { }) {
        assertions = [
          {
            assertion = config.virtualisation.incus.enable;
            message = "ryk.incus.instances needs virtualisation.incus.enable on this host.";
          }
        ];

        systemd.services.incus-instances = {
          description = "Reconcile declared Incus instances";

          after = [
            "incus.service"
            "incus-preseed.service"
            "network-online.target"
          ];
          requires = [ "incus.service" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          path = [ pkgs.coreutils ];
          script = reconcile;

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Creating a guest pulls an image; a cold first run is slow.
            TimeoutStartSec = "30min";
          };
        };
      };
    };
}
