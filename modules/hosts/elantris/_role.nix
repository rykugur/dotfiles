{
  inputs,
  pkgs,
  ...
}:
let
  sshKeys = import ./_ssh-keys.nix;
  dustySshKeys = import ../../misc/_dusty-ssh-keys.nix;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  networking = {
    hostName = "elantris";
    # Deliberately NOT AdGuard (10.3.9.5/.6, as nale uses): this VLAN's own
    # UniFi DHCP server hands out 1.1.1.1/9.9.9.9 only, and the firewall
    # blocks the guest from reaching AdGuard or any other LAN DNS at all.
    # An explicit `networking.nameservers` here would just duplicate (or
    # worse, diverge from) what DHCP already provides.
    firewall.enable = true;
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # OOM headroom. zram alone is not enough here: a single OMP derivation
  # (Bun/Zig) peaked ~7.5G of this guest's 7.7G, so compressing RAM into
  # more RAM doesn't help — it needs somewhere off-RAM to spill. roshar has
  # no memory to grow the VM into (26/31G used), but the 64G disk is nearly
  # empty, so 10G of btrfs swapfile is the cheap fix. Created live with
  # `btrfs filesystem mkswapfile --size 10g /swapfile` (which sets NOCOW
  # for us); this declaration just makes it survive a generation switch.
  swapDevices = [ { device = "/swapfile"; } ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
    trusted-users = [
      "root"
      "world"
      "dusty"
    ];
    # comin builds locally here (no vasher cache — this host can't reach the
    # LAN by design), and OMP comes from a flake input that isn't on
    # cache.nixos.org, so it compiles from source including Rust deps. At
    # max-jobs=2 that peaked 7.2G and the kernel OOM-killed comin on this
    # 8G guest. roshar has no spare RAM to grow the VM into (26/31G used),
    # so cap concurrency instead.
    max-jobs = 1;
    cores = 2;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  services.openssh.settings = {
    PermitRootLogin = "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  # Root stays reachable by key so a broken comin generation can be repaired
  # over SSH without the Proxmox console. `world` runs the rig; sudo access
  # for it (not the exact agent execution model — root vs. sudo per agent —
  # which is still open, see [[OpenRig Agent World]]) is deliberately
  # unrestricted here: the VM itself, not an in-guest permission boundary,
  # is what isolates this host.
  users.users.root.openssh.authorizedKeys.keys = sshKeys;
  users.users.world = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
  };
  # Dusty's own admin login, at his request: inbound SSH only, no outbound
  # credential or access this guest wouldn't otherwise have.
  users.users.dusty = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = dustySshKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  # Phase 2 scope only: get the VM booting with OpenRig's CLI functional.
  # The rig itself (personas, /world layout, culture rules, caddy service)
  # is Phase 4 — see the brief and [[OpenRig Agent World]].
  environment.systemPackages = with pkgs; [
    openrig
    nodejs_22
    tmux
    git
    caddy
    python3
    gcc
    gnumake
    jq
  ];

  system.stateVersion = "26.05";
}
