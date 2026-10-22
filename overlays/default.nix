{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions =
    final: _prev:
    import ../pkgs {
      pkgs = final;
      inherit inputs;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications =
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
    in
    {
      # TEMPORARY — REVIEW BY 2026-10-28.
      #
      # nixpkgs 6bd75267 (PR #571181, 2026-10-13) made aggregateModules merge a
      # <mod>.ko.cer for every external kernel module. Packages that copy their
      # .ko by hand instead of going through Kbuild's modules_install never
      # produce one, so `cat` fails, xargs exits 123, and the whole kernel
      # module tree fails to build. Upstream issue: NixOS/nixpkgs#575192.
      #
      # The first three mirror upstream fixes; drop each as nixos-unstable picks
      # them up:
      #   r8125       PR #576564 (merged 2026-10-21)
      #   openrazer   PR #576293 (merged 2026-10-20)
      #   xpad-noone  PR #576469 (open)
      #
      # Separately, kernel.dev now ships System.map, so v4l2loopback's
      # modules_install runs depmod and emits modules.alias/dep into its output.
      # Those collide with the kernel's files in aggregateModules (#576406).
      # Mirror the install fix from nixpkgs PR #575861 to skip depmod.
      # jezrien runs boot.kernelPackages = pkgs.linuxPackages_zen, and that set
      # is built by linuxKernel.packagesFor internally — overriding the
      # pkgs.linuxPackagesFor alias does nothing.
      linuxPackages_zen = prev.lib.warn
        "overlays: local kernel-module install workarounds are active (nixpkgs#575192, #576406). Review r8125/openrazer/xpad-noone/v4l2loopback by 2026-10-28."
        (
          prev.linuxPackages_zen.extend (
            _: kprev:
            let
              build = "${kprev.kernel.dev}/lib/modules/${kprev.kernel.modDirVersion}/build";
              out = builtins.placeholder "out";
            in
            {
                r8125 = kprev.r8125.overrideAttrs (old: {
                  # The packaged preBuild also rewrites modules_install to pin
                  # INSTALL_MOD_PATH, which upstream dropped in favour of the
                  # makeFlag below; keep only the BASEDIR relaxation.
                  preBuild = null;
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace src/Makefile --replace-fail "BASEDIR :=" "BASEDIR ?="
                  '';
                  makeFlags = old.makeFlags ++ [
                    "INSTALL_MOD_PATH=${out}"
                    "INSTALL_MOD_DIR=kernel/drivers/net/ethernet/realtek"
                    "INSTALL_MOD_STRIP=1"
                    "DEPMOD=true"
                  ];
                  installPhase = null;
                  installTargets = [ "modules_install" ];
                  installFlags = [
                    "-C"
                    build
                    "M=$(PWD)/src"
                  ];
                });

                openrazer = kprev.openrazer.overrideAttrs (old: {
                  makeFlags = old.makeFlags ++ [
                    "INSTALL_MOD_PATH=${out}"
                    "INSTALL_MOD_DIR=kernel/drivers/hid"
                    "INSTALL_MOD_STRIP=1"
                    "DEPMOD=true"
                  ];
                  # Upstream keeps only the udev/razer_mount half, as postInstall.
                  installPhase = null;
                  installTargets = [ "modules_install" ];
                  installFlags = [
                    "-C"
                    build
                    "M=$(PWD)/driver"
                  ];
                  postInstall = ''
                    RAZER_MOUNT_OUT="$out/bin/razer_mount"
                    RAZER_RULES_OUT="$out/etc/udev/rules.d/99-razer.rules"
                    install -m 644 -v -D install_files/udev/99-razer.rules $RAZER_RULES_OUT
                    install -m 755 -v -D install_files/udev/razer_mount $RAZER_MOUNT_OUT
                    substituteInPlace $RAZER_RULES_OUT \
                      --replace razer_mount $RAZER_MOUNT_OUT \
                      --replace plugdev openrazer
                    substituteInPlace $RAZER_MOUNT_OUT \
                      --replace /usr/bin/logger ${prev.util-linux}/bin/logger \
                      --replace chgrp ${prev.coreutils}/bin/chgrp \
                      --replace "PATH='/sbin:/bin:/usr/sbin:/usr/bin'" "" \
                      --replace plugdev openrazer
                  '';
                });

                xpad-noone = kprev.xpad-noone.overrideAttrs (old: {
                  makeFlags = old.makeFlags ++ [
                    "KERNEL_SRC=${build}"
                    "INSTALL_MOD_PATH=${out}"
                    "INSTALL_MOD_DIR=kernel/drivers/xpad-noone"
                    "INSTALL_MOD_STRIP=1"
                    "DEPMOD=true"
                  ];
                  installPhase = null;
                  installTargets = [ "modules_install" ];
                  installFlags = [
                    "-C"
                    build
                    "M=$(PWD)"
                  ];
                });

                v4l2loopback = kprev.v4l2loopback.overrideAttrs (_: {
                  preBuild = null;
                  installFlags = [
                    "DEPMOD=true"
                    "INSTALL_MOD_PATH=${out}"
                  ];
                });
              }
            )
          );

      # openldap's syncreplication test (test017) is timing-sensitive and flaky in Nix's sandbox
      openldap = prev.openldap.overrideAttrs (_: {
        doCheck = false;
      });
      rtk = prev.rtk.overrideAttrs (_: {
        doCheck = false;
      });
      # 3.2.1 still calls obs_properties_add_button; OBS 32.2 deprecates it and the plugin's -Werror fails the build.
      obs-studio-plugins = prev.obs-studio-plugins // {
        obs-move-transition = prev.obs-studio-plugins.obs-move-transition.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DCMAKE_COMPILE_WARNING_AS_ERROR=OFF" ];
        });
      };

      audiorelay = prev.callPackage "${inputs.ryze312-stackpkgs}/packages/audiorelay.nix" { };
      hyprprop = inputs.hyprland-contrib.packages.${system}.hyprprop;
      hyprland-qtutils = inputs.hyprland-qtutils.packages."${system}".default;

      kubernetes-helm-wrapped = prev.wrapHelm prev.kubernetes-helm {
        plugins = with prev.kubernetes-helmPlugins; [
          helm-diff
          helm-secrets
          helm-s3
        ];
      };
      karabiner-elements = prev.karabiner-elements.overrideAttrs (old: {
        version = "14.13.0";
        src = prev.fetchurl {
          inherit (old.src) url;
          hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
        };
      });
      zsm = inputs.zmx-session-manager.packages.${system}.default;

      lib = prev.lib // {
        fetch7z =
          { url, sha256 }:
          let
            filename = baseNameOf url;
            pname = final.lib.strings.removeSuffix ".7z" filename;
            archive = prev.fetchurl { inherit url sha256; };
          in
          prev.runCommand pname
            {
              src = archive;
              nativeBuildInputs = [ prev.p7zip ];
              preferLocalBuild = true;
              allowSubstitutes = false;
              # outputHashMode = "recursive";
              # outputHashAlgo = "sha256";
            }
            ''
              mkdir -p $out
              7za x $src -o$out

              # strip top-level dir
              if [ "$(ls -A $out)" = "${pname}" ] || [ "$(ls -A $out)" = "GraphicsLib_1.12.1" ]; then  # Adjust if needed
                mv $out/* $out/ 2>/dev/null || true
                rmdir $out/$(ls -A $out 2>/dev/null) 2>/dev/null || true
              fi          
            '';
      };
    };
}
