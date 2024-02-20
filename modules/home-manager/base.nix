{ pkgs, ... }: {
  home.packages = with pkgs; [
    mousai
    speedtest-cli
  ];
}
