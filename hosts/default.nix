{ pkgs, username, ... }: {
  config = {
    time.timeZone = "America/Chicago";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_GB.UTF-8"; # for 24 hour format
    };

    nix = {
      buildMachines = [{
        hostName = "taldain";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 3;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }];
      distributedBuilds = true;
    };

    environment.systemPackages = with pkgs; [ git neovim nix-search-cli ];
  };
}
