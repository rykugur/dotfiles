# Legacy Module Final Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert all remaining legacy modules (except desktop WM stack) to dendritic flake-parts pattern and remove the legacy-modules import from jezrien.

**Architecture:** Each legacy module becomes a single `.nix` file registered via `flake.modules.<class>.<name>`. Modules with both NixOS and home-manager config co-locate both in one file. All `mkEnableOption`/`mkIf` wrappers are stripped — opt-in is by importing.

**Tech Stack:** Nix, flake-parts, home-manager

**Spec:** `docs/superpowers/specs/2026-04-05-legacy-module-final-migration-design.md`

---

### Task 1: Create simple NixOS-only system modules

These are straightforward 1:1 conversions. Each strips the `mkEnableOption`/`mkIf` wrapper and registers via `flake.modules.nixos.<name>`.

**Files:**
- Create: `modules/nixos/1password.nix`
- Create: `modules/nixos/btrfs.nix`
- Create: `modules/nixos/obs-studio.nix`
- Create: `modules/nixos/wooting.nix`
- Create: `modules/nixos/zsa.nix`

- [ ] **Step 1: Create `modules/nixos/1password.nix`**

```nix
{ ... }:
{
  flake.modules.nixos._1password =
    { username, pkgs, ... }:
    {
      environment.etc."1password/custom_allowed_browsers" = {
        text = ''
          chrome
          vivald-bin
          # because they keep fucking changing it...
          .zen-beta-wrapped
          .zen-beta-wrapp
          .zen-beta
          zen-beta
          zen
        '';
        mode = "0755";
      };

      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "${username}" ];
      };
    };
}
```

- [ ] **Step 2: Create `modules/nixos/btrfs.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.btrfs =
    { ... }:
    {
      services = {
        fstrim = {
          enable = true;
          interval = "weekly";
        };

        btrfs.autoScrub = {
          enable = true;
          interval = "monthly";
          fileSystems = [ "/" ];
        };
      };
    };
}
```

- [ ] **Step 3: Create `modules/nixos/obs-studio.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.obs-studio =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ libva-utils ];

      programs.obs-studio = {
        enable = true;

        plugins = with pkgs.obs-studio-plugins; [
          input-overlay
          wlrobs
          obs-backgroundremoval
          obs-composite-blur
          obs-move-transition
          obs-pipewire-audio-capture
          obs-vaapi
          obs-gstreamer
          obs-vkcapture
        ];
      };
    };
}
```

- [ ] **Step 4: Create `modules/nixos/wooting.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.wooting =
    { pkgs, ... }:
    {
      services.udev = {
        enable = true;
        packages = [ pkgs.via pkgs.vial ];
        extraRules = ''
          # Wooting One Legacy
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"

          # Wooting One update mode
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess"

          # Wooting Two Legacy
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"

          # Wooting Two update mode
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess"

          # Generic Wootings
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="31e3", TAG+="uaccess"
        '';
      };
    };
}
```

- [ ] **Step 5: Create `modules/nixos/zsa.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.zsa =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.keymapp ];
      hardware.keyboard.zsa.enable = true;
    };
}
```

- [ ] **Step 6: Commit**

```bash
git add modules/nixos/
git commit -m "feat: convert 1password, btrfs, obs-studio, wooting, zsa to dendritic modules"
```

---

### Task 2: Create NixOS system modules that use `username`

These modules reference the `username` specialArg.

**Files:**
- Create: `modules/nixos/razer.nix`
- Create: `modules/desktop/kde.nix`

- [ ] **Step 1: Create `modules/nixos/razer.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.razer =
    { username, pkgs, ... }:
    {
      hardware.openrazer = {
        enable = true;
        users = [ "${username}" ];
      };

      services.input-remapper.enable = true;

      environment.systemPackages = with pkgs; [ piper polychromatic ];
    };
}
```

- [ ] **Step 2: Create `modules/desktop/kde.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.kde =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.catppuccin-sddm.override {
          flavor = "mocha";
          font = "ZedMono";
          fontSize = "9";
          loginBackground = true;
        })
        (pkgs.catppuccin-kde.override { flavour = [ "mocha" ]; })
        pkgs.catppuccin-cursors.mochaBlue
      ];

      programs.ssh.askPassword =
        pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

      services = {
        power-profiles-daemon.enable = true;
        xserver.enable = true;
        displayManager.sddm = {
          enable = true;
          autoNumlock = true;
        };
        desktopManager.plasma6.enable = true;
      };
    };
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/nixos/razer.nix modules/desktop/kde.nix
git commit -m "feat: convert razer, kde to dendritic modules"
```

---

### Task 3: Create gaming NixOS modules

**Files:**
- Create: `modules/gaming/gamemode.nix`
- Create: `modules/gaming/steam.nix`
- Create: `modules/gaming/vr.nix`

- [ ] **Step 1: Create `modules/gaming/gamemode.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.gamemode =
    { pkgs, ... }:
    {
      programs.gamemode = {
        enable = true;
        settings = {
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
          };
        };
      };
    };
}
```

- [ ] **Step 2: Create `modules/gaming/steam.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.steam =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;

        extraCompatPackages = [ pkgs.proton-ge-bin ];

        protontricks.enable = true;
      };
    };
}
```

- [ ] **Step 3: Create `modules/gaming/vr.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.vr =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wlx-overlay-s ];

      programs.alvr = {
        enable = true;
        openFirewall = true;
      };

      services = {
        monado.enable = true;
        wivrn = {
          enable = true;
          openFirewall = true;
        };
      };
    };
}
```

- [ ] **Step 4: Commit**

```bash
git add modules/gaming/gamemode.nix modules/gaming/steam.nix modules/gaming/vr.nix
git commit -m "feat: convert gamemode, steam, vr to dendritic modules"
```

---

### Task 4: Create gaming home-manager modules

**Files:**
- Create: `modules/gaming/audiorelay.nix`
- Create: `modules/gaming/jackify.nix`
- Create: `modules/gaming/nexus-mods.nix`

- [ ] **Step 1: Create `modules/gaming/audiorelay.nix`**

Audiorelay has both NixOS (firewall) and home-manager (package) sides.

```nix
{ self, ... }:
{
  flake.modules.nixos.audiorelay =
    { username, ... }:
    {
      networking.firewall = {
        allowedTCPPorts = [ 59100 ];
        allowedUDPPorts = [ 59100 ];
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.audiorelay ];
    };

  flake.modules.homeManager.audiorelay =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.audiorelay ];
    };
}
```

- [ ] **Step 2: Create `modules/gaming/jackify.nix`**

Home-manager only — just installs the package.

```nix
{ ... }:
{
  flake.modules.homeManager.jackify =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jackify ];
    };
}
```

- [ ] **Step 3: Create `modules/gaming/nexus-mods.nix`**

Home-manager only — package + mime handler.

```nix
{ ... }:
{
  flake.modules.homeManager.nexus-mods =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nexusmods-app-unfree ];

      xdg = {
        enable = true;
        mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/nxm" = [ "com.nexusmods.app.desktop" ];
          };
        };
      };
    };
}
```

- [ ] **Step 4: Commit**

```bash
git add modules/gaming/audiorelay.nix modules/gaming/jackify.nix modules/gaming/nexus-mods.nix
git commit -m "feat: convert audiorelay, jackify, nexus-mods to dendritic modules"
```

---

### Task 5: Create misc and virtualization modules

**Files:**
- Create: `modules/misc/appimage.nix`
- Create: `modules/misc/distrobox.nix`
- Create: `modules/virtualization/docker.nix`
- Create: `modules/virtualization/winboat.nix`
- Create: `modules/virtualization/vfio.nix`
- Create: `modules/virtualization/virtman.nix`

- [ ] **Step 1: Create `modules/misc/appimage.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.appimage =
    { ... }:
    {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
}
```

- [ ] **Step 2: Create `modules/misc/distrobox.nix`**

Co-located nixos + homeManager.

```nix
{ self, ... }:
{
  flake.modules.nixos.distrobox =
    { username, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ virtiofsd ];

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };

      home-manager.users.${username}.imports = [ self.modules.homeManager.distrobox ];
    };

  flake.modules.homeManager.distrobox =
    { ... }:
    {
      programs.distrobox.enable = true;
    };
}
```

- [ ] **Step 3: Create `modules/virtualization/docker.nix`**

Fix hardcoded `"dusty"` to use `username` specialArg.

```nix
{ ... }:
{
  flake.modules.nixos.docker =
    { username, lib, pkgs, ... }:
    {
      virtualisation.docker = {
        enable = true;
        storageDriver = lib.mkDefault "btrfs";
      };

      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      users.users.${username}.extraGroups = [ "docker" ];
    };
}
```

- [ ] **Step 4: Create `modules/virtualization/winboat.nix`**

No longer force-enables docker — host imports both modules separately.

```nix
{ ... }:
{
  flake.modules.nixos.winboat =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.winboat
        pkgs.freerdp
      ];
    };
}
```

- [ ] **Step 5: Create `modules/virtualization/vfio.nix`**

Keeps `mkOption` for `vfioIds` since it's parameterized per-host data.

```nix
{ ... }:
{
  flake.modules.nixos.vfio =
    { config, lib, username, pkgs, ... }:
    let
      cfg = config.ryk.vfio;
      vfioIds = cfg.ids;
      vfioIdsFmt = with builtins;
        if (length vfioIds > 0) then concatStringsSep "," vfioIds else "";
    in
    {
      options.ryk.vfio.ids = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "A list of vfio PCI device IDs to pass through.";
      };

      config = {
        boot = {
          kernelParams = [ "amd_iommu=on" ];
          kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
          extraModprobeConfig = "options vfio-pci ids=${vfioIdsFmt}";
        };

        hardware.graphics.enable = true;

        systemd.tmpfiles.rules =
          [ "f /dev/shm/looking-glass 0660 ${username} qemu-libvirtd -" ];

        environment.systemPackages = with pkgs; [ looking-glass-client OVMF ];

        programs.virt-manager.enable = true;

        virtualisation = {
          spiceUSBRedirection.enable = true;

          libvirtd = {
            enable = true;
            onBoot = "ignore";
            onShutdown = "shutdown";

            qemuOvmf = true;
            qemuRunAsRoot = true;

            qemu = {
              package = pkgs.qemu_kvm;
              verbatimConfig = ''
                namespaces = []
                user = "${username}"
              '';
            };
          };
        };

        users.users.${username}.extraGroups = [ "qemu-libvirtd" "libvirtd" "disk" ];
      };
    };
}
```

- [ ] **Step 6: Create `modules/virtualization/virtman.nix`**

```nix
{ ... }:
{
  flake.modules.nixos.virtman =
    { username, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ virtiofsd ];

      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [
              (pkgs.OVMF.override {
                secureBoot = true;
                tpmSupport = true;
              }).fd
            ];
          };
        };
      };

      programs.virt-manager.enable = true;

      users.users.${username}.extraGroups = [ "libvirtd" ];
    };
}
```

- [ ] **Step 7: Commit**

```bash
git add modules/misc/appimage.nix modules/misc/distrobox.nix modules/virtualization/
git commit -m "feat: convert appimage, distrobox, docker, winboat, vfio, virtman to dendritic modules"
```

---

### Task 6: Update jezrien host to use new modules

**Files:**
- Modify: `modules/hosts/jezrien/default.nix`
- Modify: `modules/hosts/jezrien/_configuration.nix`

- [ ] **Step 1: Update `modules/hosts/jezrien/default.nix` — replace legacy imports with dendritic modules**

Remove lines 16-17:
```nix
      ../../../legacy-modules/nixos
      ../../../legacy-modules
```

Add after the existing `self.modules.nixos.*` entries (after line 32, `self.modules.nixos.starcitizen`):

```nix
      self.modules.nixos._1password
      self.modules.nixos.btrfs
      self.modules.nixos.zsa
      self.modules.nixos.razer
      self.modules.nixos.obs-studio
      self.modules.nixos.gamemode
      self.modules.nixos.steam
      self.modules.nixos.appimage
```

- [ ] **Step 2: Update `modules/hosts/jezrien/default.nix` — add HM modules**

Add `jackify` and `nexus-mods` to the `hmModules` list (alongside `keebs`, `starsector`, etc.):

```nix
                jackify
                nexus-mods
```

- [ ] **Step 3: Update `modules/hosts/jezrien/_configuration.nix` — trim ryk block**

Replace the entire `ryk = { ... };` block (lines 158-189) with:

```nix
  ryk = {
    dankMaterialShell.screenshotBackend = "swappy";
    pipewire.quantum = 256;
  };
```

- [ ] **Step 4: Commit**

```bash
git add modules/hosts/jezrien/default.nix modules/hosts/jezrien/_configuration.nix
git commit -m "feat: switch jezrien from legacy-modules to dendritic imports"
```

---

### Task 7: Delete legacy module files (non-desktop)

Only delete files that have been migrated. Leave `legacy-modules/desktop/` intact.

**Files:**
- Delete: `legacy-modules/default.nix`
- Delete: `legacy-modules/dev/default.nix`
- Delete: `legacy-modules/nixos/default.nix`
- Delete: `legacy-modules/nixos/1password.nix`
- Delete: `legacy-modules/nixos/btrfs.nix`
- Delete: `legacy-modules/nixos/distrobox.nix`
- Delete: `legacy-modules/nixos/gamemode.nix`
- Delete: `legacy-modules/nixos/kde.nix`
- Delete: `legacy-modules/nixos/obs-studio.nix`
- Delete: `legacy-modules/nixos/razer.nix`
- Delete: `legacy-modules/nixos/steam.nix`
- Delete: `legacy-modules/nixos/vfio.nix`
- Delete: `legacy-modules/nixos/virtman.nix`
- Delete: `legacy-modules/nixos/wooting.nix`
- Delete: `legacy-modules/nixos/zsa.nix`
- Delete: `legacy-modules/gaming/default.nix`
- Delete: `legacy-modules/gaming/audiorelay/default.nix`
- Delete: `legacy-modules/gaming/audiorelay/home.nix`
- Delete: `legacy-modules/gaming/jackify/default.nix`
- Delete: `legacy-modules/gaming/jackify/home.nix`
- Delete: `legacy-modules/gaming/nexus-mods/default.nix`
- Delete: `legacy-modules/gaming/nexus-mods/home.nix`
- Delete: `legacy-modules/gaming/vr/default.nix`
- Delete: `legacy-modules/misc/default.nix`
- Delete: `legacy-modules/misc/appimage/default.nix`
- Delete: `legacy-modules/virtualization/default.nix`
- Delete: `legacy-modules/virtualization/docker.nix`
- Delete: `legacy-modules/virtualization/winboat.nix`

- [ ] **Step 1: Delete migrated legacy files**

```bash
# nixos modules
rm legacy-modules/nixos/1password.nix
rm legacy-modules/nixos/btrfs.nix
rm legacy-modules/nixos/distrobox.nix
rm legacy-modules/nixos/gamemode.nix
rm legacy-modules/nixos/kde.nix
rm legacy-modules/nixos/obs-studio.nix
rm legacy-modules/nixos/razer.nix
rm legacy-modules/nixos/steam.nix
rm legacy-modules/nixos/vfio.nix
rm legacy-modules/nixos/virtman.nix
rm legacy-modules/nixos/wooting.nix
rm legacy-modules/nixos/zsa.nix
rm legacy-modules/nixos/default.nix

# gaming modules
rm legacy-modules/gaming/audiorelay/default.nix
rm legacy-modules/gaming/audiorelay/home.nix
rmdir legacy-modules/gaming/audiorelay
rm legacy-modules/gaming/jackify/default.nix
rm legacy-modules/gaming/jackify/home.nix
rmdir legacy-modules/gaming/jackify
rm legacy-modules/gaming/nexus-mods/default.nix
rm legacy-modules/gaming/nexus-mods/home.nix
rmdir legacy-modules/gaming/nexus-mods
rm legacy-modules/gaming/vr/default.nix
rmdir legacy-modules/gaming/vr
rm legacy-modules/gaming/default.nix
rmdir legacy-modules/gaming

# misc modules
rm legacy-modules/misc/appimage/default.nix
rmdir legacy-modules/misc/appimage
rm legacy-modules/misc/default.nix
rmdir legacy-modules/misc

# virtualization modules
rm legacy-modules/virtualization/docker.nix
rm legacy-modules/virtualization/winboat.nix
rm legacy-modules/virtualization/default.nix
rmdir legacy-modules/virtualization

# dev stub and top-level aggregator
rm legacy-modules/dev/default.nix
rmdir legacy-modules/dev
rm legacy-modules/default.nix

# nixos directory should now be empty
rmdir legacy-modules/nixos
```

After deletion, `legacy-modules/` should contain only:
```
legacy-modules/
  darwin/
    default.nix
  desktop/
    ...
```

- [ ] **Step 2: Verify remaining legacy-modules structure**

```bash
find legacy-modules/ -type f | sort
```

Expected output — only desktop and darwin files remain:
```
legacy-modules/darwin/default.nix
legacy-modules/desktop/default.nix
legacy-modules/desktop/dankMaterialShell/default.nix
legacy-modules/desktop/dankMaterialShell/home.nix
legacy-modules/desktop/hyprland/default.nix
legacy-modules/desktop/hyprland/home.nix
legacy-modules/desktop/keybinds.nix
legacy-modules/desktop/niri/default.nix
legacy-modules/desktop/niri/home.nix
legacy-modules/desktop/noctalia/default.nix
legacy-modules/desktop/noctalia/home.nix
legacy-modules/desktop/shared.nix
```

- [ ] **Step 3: Commit**

```bash
git add -A legacy-modules/
git commit -m "chore: delete migrated legacy module files

Desktop and darwin stubs remain for future migration."
```

---

### Task 8: Validate the build

- [ ] **Step 1: Check flake evaluation**

```bash
nix flake check 2>&1 | head -50
```

Expected: no errors related to missing `ryk.*` options or module imports.

- [ ] **Step 2: Dry-build jezrien**

```bash
nix build .#nixosConfigurations.jezrien.config.system.build.toplevel --dry-run 2>&1 | tail -20
```

Expected: successful evaluation (derivation resolves without errors). A dry-run confirms the module wiring is correct without downloading/building everything.

- [ ] **Step 3: If build errors occur, fix and commit**

Common issues to watch for:
- Missing `username` in module args — add it to the function args
- `ryk.*` option referenced but not defined — missed a removal in `_configuration.nix`
- Module name collision — two modules register the same `flake.modules.nixos.<name>`

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve build errors from legacy module migration"
```
