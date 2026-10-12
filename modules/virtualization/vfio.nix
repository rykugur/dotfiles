{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      enabledNixos = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.modules.nixos.meta
          self.modules.nixos.vfio
          {
            nixpkgs.config.allowUnfree = true;
            boot.isContainer = true;
            fileSystems."/" = {
              device = "none";
              fsType = "tmpfs";
            };
            system.stateVersion = "25.11";
            ryk.vfio = {
              enable = true;
              domainName = "windows-vm-check";
              gpu.pciAddress = "0000:01:00.0";
              audio.pciAddress = "0000:01:00.1";
              usbDevices = [
                {
                  name = "check-1";
                  vendorId = "0001";
                  productId = "0001";
                }
                {
                  name = "check-2";
                  vendorId = "0002";
                  productId = "0002";
                }
                {
                  name = "check-3";
                  vendorId = "0003";
                  productId = "0003";
                }
                {
                  name = "check-4";
                  vendorId = "0004";
                  productId = "0004";
                }
                {
                  name = "check-5";
                  vendorId = "0005";
                  productId = "0005";
                }
              ];
            };
          }
        ];
      };
    in
    pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      checks.windows-vfio = pkgs.runCommand "windows-vfio-check" {
        enabledSystem = enabledNixos.config.system.build.toplevel;
        nativeBuildInputs = [
          pkgs.libvirt
          pkgs.python3
        ];
      } ''
        mkdir -p source/modules/virtualization
        cp -r ${./_vfio} source/modules/virtualization/_vfio
        chmod -R u+w source
        cd source

        export PYTHONDONTWRITEBYTECODE=1
        python -m py_compile \
          modules/virtualization/_vfio/windows_vm.py \
          modules/virtualization/_vfio/tests/test_windows_vm.py \
          modules/virtualization/_vfio/tests/test_domain.py
        python -m unittest discover -s modules/virtualization/_vfio/tests -v

        test -e "$enabledSystem"

        touch "$out"
      '';
    };

  flake.modules.nixos.vfio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ryk.vfio;
      username = config.ryk.username;

      windowsFirmware = pkgs.runCommand "windows-vm-firmware" {
        nativeBuildInputs = [ pkgs.jq ];
      } ''
        mapfile -t firmware_pairs < <(
          jq -r '
            select(any(.targets[]?; .architecture == "x86_64"))
            | select(any(.features[]?; . == "secure-boot"))
            | select(any(.features[]?; . == "enrolled-keys"))
            | [.mapping.executable.filename, .mapping."nvram-template".filename]
            | @tsv
          ' ${pkgs.qemu_kvm}/share/qemu/firmware/*.json | sort -u
        )

        if (( ''${#firmware_pairs[@]} != 1 )); then
          echo "expected exactly one x86_64 Secure Boot firmware pair" >&2
          printf '%s\n' "''${firmware_pairs[@]}" >&2
          exit 1
        fi

        IFS=$'\t' read -r code vars <<< "''${firmware_pairs[0]}"
        test -f "$code"
        test -f "$vars"
        mkdir -p "$out"
        ln -s "$code" "$out/code.fd"
        ln -s "$vars" "$out/vars.fd"
      '';

      parsePciAddress =
        address:
        let
          parsed = builtins.match "^([0-9A-Fa-f]{4}):([0-9A-Fa-f]{2}):([0-9A-Fa-f]{2})\\.([0-7])$" address;
        in
        if parsed == null then
          [
            "0000"
            "00"
            "00"
            "0"
          ]
        else
          map lib.toLower parsed;

      gpuAddress = parsePciAddress cfg.gpu.pciAddress;
      audioAddress = parsePciAddress cfg.audio.pciAddress;
      paddedUsbDevices = cfg.usbDevices ++ lib.replicate 5 {
        name = "invalid";
        vendorId = "0000";
        productId = "0000";
      };
      usbDevice = index: builtins.elemAt paddedUsbDevices index;

      xmlSubstitutions = {
        domainName = cfg.domainName;
        memoryMiB = toString cfg.memoryMiB;
        vcpus = toString cfg.vcpus;
        diskPath = "/var/lib/libvirt/images/${cfg.domainName}.qcow2";
        ovmfCode = "${windowsFirmware}/code.fd";
        ovmfVars = "/var/lib/libvirt/qemu/nvram/${cfg.domainName}_VARS.fd";
        ovmfVarsTemplate = "${windowsFirmware}/vars.fd";
        virtioIso = "${pkgs.virtio-win}/share/virtio-win/virtio-win.iso";
        windowsIso = "/var/lib/libvirt/images/${cfg.domainName}-install.iso";
        gpuDomain = builtins.elemAt gpuAddress 0;
        gpuBus = builtins.elemAt gpuAddress 1;
        gpuSlot = builtins.elemAt gpuAddress 2;
        gpuFunction = builtins.elemAt gpuAddress 3;
        audioDomain = builtins.elemAt audioAddress 0;
        audioBus = builtins.elemAt audioAddress 1;
        audioSlot = builtins.elemAt audioAddress 2;
        audioFunction = builtins.elemAt audioAddress 3;
        usb1Vendor = lib.toLower (usbDevice 0).vendorId;
        usb1Product = lib.toLower (usbDevice 0).productId;
        usb2Vendor = lib.toLower (usbDevice 1).vendorId;
        usb2Product = lib.toLower (usbDevice 1).productId;
        usb3Vendor = lib.toLower (usbDevice 2).vendorId;
        usb3Product = lib.toLower (usbDevice 2).productId;
        usb4Vendor = lib.toLower (usbDevice 3).vendorId;
        usb4Product = lib.toLower (usbDevice 3).productId;
        usb5Vendor = lib.toLower (usbDevice 4).vendorId;
        usb5Product = lib.toLower (usbDevice 4).productId;
      };

      normalXml = pkgs.replaceVars ./_vfio/domain.xml.in xmlSubstitutions;
      installXml = pkgs.replaceVars ./_vfio/domain-install.xml.in xmlSubstitutions;

      controllerConfig = pkgs.writeText "${cfg.domainName}-controller.json" (
        builtins.toJSON {
          domainName = cfg.domainName;
          inherit username;
          gpu = cfg.gpu.pciAddress;
          audio = cfg.audio.pciAddress;
          usbDevices = map (device: {
            vendorId = lib.toLower device.vendorId;
            productId = lib.toLower device.productId;
          }) cfg.usbDevices;
          diskPath = xmlSubstitutions.diskPath;
          diskSizeGiB = cfg.diskSizeGiB;
          normalXml = normalXml;
          installXml = installXml;
          installIsoPath = xmlSubstitutions.windowsIso;
          stateDirectory = "/var/lib/windows-vm";
        }
      );

      windowsVmControl = pkgs.writeTextFile {
        name = "windows-vm-control";
        destination = "/bin/windows-vm-control";
        executable = true;
        text = ''
          #!${pkgs.python3}/bin/python3
          ${builtins.readFile ./_vfio/windows_vm.py}
        '';
      };

      windowsVm = pkgs.writeShellApplication {
        name = "windows-vm";
        runtimeInputs = [
          pkgs.procps
          pkgs.psmisc
          pkgs.systemd
        ];
        text = ''
          if [ "$#" -eq 1 ] && [ "$1" = "--check" ]; then
            exec ${windowsVmControl}/bin/windows-vm-control --config ${controllerConfig} check
          fi

          if [ "$#" -ne 0 ]; then
            echo "usage: windows-vm [--check]" >&2
            exit 2
          fi

          exec systemctl start windows-vm.service
        '';
      };

      preparePath = lib.makeBinPath [ pkgs.qemu_kvm ];
      windowsVmInstall = pkgs.writeShellApplication {
        name = "windows-vm-install";
        runtimeInputs = [
          pkgs.sudo
          pkgs.systemd
        ];
        text = ''
          if [ "$#" -ne 1 ]; then
            echo "usage: windows-vm-install <windows-iso>" >&2
            exit 2
          fi

          sudo -- ${pkgs.coreutils}/bin/env PATH=${preparePath} \
            ${windowsVmControl}/bin/windows-vm-control \
            --config ${controllerConfig} prepare-install --iso "$1"
          exec systemctl start windows-vm.service
        '';
      };

      usbAttach = pkgs.writeShellScript "windows-vm-usb-attach" ''
        identity="$1"
        if [[ ! "$identity" =~ ^[0-9a-f]{4}:[0-9a-f]{4}$ ]]; then
          echo "invalid USB identity: $identity" >&2
          exit 2
        fi

        vendor="''${identity%%:*}"
        product="''${identity#*:}"
        exec ${windowsVmControl}/bin/windows-vm-control \
          --config ${controllerConfig} attach-usb "$vendor" "$product"
      '';

      usbRules = lib.concatMapStringsSep "\n" (
        device:
        let
          vendorId = lib.toLower device.vendorId;
          productId = lib.toLower device.productId;
        in
        ''ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="${vendorId}", ATTR{idProduct}=="${productId}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="windows-vm-usb-attach@${vendorId}:${productId}.service"''
      ) cfg.usbDevices;
    in
    {
      options.ryk.vfio = {
        enable = lib.mkEnableOption "the Windows VFIO session";

        domainName = lib.mkOption {
          type = lib.types.strMatching "[A-Za-z0-9._-]+";
          default = "windows-vm";
          description = "Libvirt domain name for the Windows VM.";
        };

        gpu = {
          pciAddress = lib.mkOption {
            type = lib.types.strMatching "[0-9A-Fa-f]{4}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}\\.[0-7]";
            description = "Full PCI address of the graphics function.";
          };
          linuxDriver = lib.mkOption {
            type = lib.types.enum [ "amdgpu" ];
            default = "amdgpu";
            description = "Linux driver restored for the graphics function.";
          };
        };

        audio = {
          pciAddress = lib.mkOption {
            type = lib.types.strMatching "[0-9A-Fa-f]{4}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}\\.[0-7]";
            description = "Full PCI address of the display-audio function.";
          };
          linuxDriver = lib.mkOption {
            type = lib.types.enum [ "snd_hda_intel" ];
            default = "snd_hda_intel";
            description = "Linux driver restored for the display-audio function.";
          };
        };

        memoryMiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = 32768;
          description = "Guest memory in MiB.";
        };

        vcpus = lib.mkOption {
          type = lib.types.ints.positive;
          default = 16;
          description = "Number of guest virtual CPUs.";
        };

        diskSizeGiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = 500;
          description = "Maximum size of the thin-provisioned guest disk in GiB.";
        };

        usbDevices = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                  description = "Human-readable USB device name.";
                };
                vendorId = lib.mkOption {
                  type = lib.types.strMatching "[0-9A-Fa-f]{4}";
                  description = "Four-digit USB vendor ID.";
                };
                productId = lib.mkOption {
                  type = lib.types.strMatching "[0-9A-Fa-f]{4}";
                  description = "Four-digit USB product ID.";
                };
              };
            }
          );
          default = [ ];
          description = "USB identities passed through to the Windows VM.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = builtins.length cfg.usbDevices == 5;
            message = "ryk.vfio.usbDevices must contain exactly five devices.";
          }
          {
            assertion = cfg.gpu.pciAddress != cfg.audio.pciAddress;
            message = "ryk.vfio GPU and audio PCI addresses must be different.";
          }
        ];

        boot = {
          kernelParams = [ "amd_iommu=on" ];
          kernelModules = lib.unique [
            "kvm-amd"
            "vfio"
            "vfio_iommu_type1"
            "vfio_pci"
            cfg.gpu.linuxDriver
            cfg.audio.linuxDriver
          ];
        };

        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = true;
            swtpm.enable = true;
          };
        };

        programs.virt-manager.enable = true;

        environment.systemPackages = [
          pkgs.libvirt
          pkgs.qemu_kvm
          pkgs.swtpm
          pkgs.virtio-win
          pkgs.virtiofsd
          windowsVmControl
          windowsVm
          windowsVmInstall
        ];

        systemd.tmpfiles.rules = [
          "d /var/lib/windows-vm 0700 root root -"
        ];

        systemd.services = {
          windows-vm = {
            description = "Windows VFIO session";
            requires = [ "libvirtd.service" ];
            after = [ "libvirtd.service" ];
            path = [
              pkgs.libvirt
              pkgs.procps
              pkgs.psmisc
              pkgs.qemu_kvm
              pkgs.systemd
            ];
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = "${windowsVmControl}/bin/windows-vm-control --config ${controllerConfig} run";
              TimeoutStartSec = "infinity";
              KillSignal = "SIGINT";
              TimeoutStopSec = "5min";
              StateDirectory = "windows-vm";
              StateDirectoryMode = "0700";
            };
          };

          "windows-vm-usb-attach@" = {
            description = "Attach configured USB device %i to the Windows VM";
            requires = [ "libvirtd.service" ];
            after = [ "libvirtd.service" ];
            path = [ pkgs.libvirt ];
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = "${usbAttach} %i";
            };
          };
        };

        security.polkit = {
          enable = true;
          extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (
                action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "windows-vm.service" &&
                action.lookup("verb") == "start" &&
                subject.user == ${builtins.toJSON username} &&
                subject.local &&
                subject.active
              ) {
                return polkit.Result.YES;
              }
            });
          '';
        };

        services.udev.extraRules = usbRules;
      };
    };
}
