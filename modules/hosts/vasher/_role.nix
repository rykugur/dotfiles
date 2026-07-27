{ inputs, pkgs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./_ssh.nix
  ];

  networking.hostName = "vasher";
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    settings = {
      experimental-features = "nix-command flakes pipe-operators";
      trusted-users = [ "root" "vasher" ];
      auto-optimise-store = true;
      max-jobs = 1;
      cores = 4;
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://nix-citizen.cachix.org"
        "https://helix.cachix.org"
        "https://pi.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      ];
    };
  };

  users.groups.vasher = { };
  users.users.vasher = {
    isSystemUser = true;
    group = "vasher";
    home = "/var/lib/vasher";
    createHome = true;
    shell = pkgs.bashInteractive;
  };


  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  networking.firewall.enable = true;
  ryk.vasherCache = {
    enable = true;
    serve = true;
  };
  ryk.vasherPrebuild.enable = true;

  environment.systemPackages = with pkgs; [ git jq ];
  system.stateVersion = "24.11";
}
