{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    nix-search-cli
  ];
}
