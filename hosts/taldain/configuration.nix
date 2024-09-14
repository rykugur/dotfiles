{ inputs, outputs, lib, config, pkgs, hostname, roles, username, ... }: {
  imports = [
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi

    inputs.home-manager.nixosModules.home-manager
    outputs.nixosModules
    roles
  ];

  raspberry-pi-nix.board = "bcm2712";

  networking = {
    hostName = hostname;
    search = [ "8.8.8.8" "8.8.4.4" ];
  };

  nixpkgs = {
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
      outputs.overlays.additions
      outputs.overlays.modifications
    ];
    config.allowUnfree = true;
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 10d";
    };

    optimise.automatic = true;

    nixPath = [ "/etc/nix/path" ];

    registry = (lib.mapAttrs (_: flake: { inherit flake; }))
      ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      substituters = [ "https://raspberry-pi-nix.cachix.org" ];
      trusted-public-keys = [
        "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
      ];
    };
  };

  environment = {
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;

    systemPackages = with pkgs; [ git neovim ];
  };

  users.users = {
    ${username} = {
      isNormalUser = true;
      initialPassword = "pass123"; # change after first login with `passwd`
      home = "/home/${username}";
      extraGroups = [ "wheel" "networkmanager" "docker" ];
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs hostname username; };
    users = { ${username} = import ./home.nix; };
    backupFileExtension = "bak";
  };

  roles.server.enable = true;
  modules = {
    programs = {
      _1password.enable = true;
      fish.enable = true;
      git.enable = true;
      nvim.enable = true;
      tmux.enable = true;
    };

    services = { ssh.enable = true; };
  };

  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53; # Port for incoming DNS Queries.
      upstreams.groups.default = [
        "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
      ];
      # For initially solving DoH/DoT Requests when no system Resolver is available.
      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = [ "1.1.1.1" "1.0.0.1" ];
      };
      #Enable Blocking of certian domains.
      blocking = {
        blackLists = {
          #Adblocking
          ads = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
          ];
          #Another filter for blocking adult sites
          adult = [ "https://blocklistproject.github.io/Lists/porn.txt" ];
          #You can add additional categories
        };
        #Configure what block categories are used
        clientGroupsBlock = {
          default = [ "ads" ];
          kids = [ "ads" "adult" ];
        };
      };
    };
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        # Listening Address
        http_addr = "127.0.0.1";
        # and Port
        http_port = 3000;
        # Grafana needs to know on which domain and URL it's running
        domain = "taldain";
        root_url =
          "https://taldain/grafana/"; # Not needed if it is `https://your.domain/`
        serve_from_sub_path = true;
      };
    };
  };
  # virtualisation.docker.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
