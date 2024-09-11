{ ... }: {
  config = {
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
  };
}
