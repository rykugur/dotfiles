{ pkgs, ... }: {
  home.packages = with pkgs; [
    kitty
  ];

  home.file = {
    ".config/kitty" = {
      source = ../../configs/kitty;
      recursive = true;
    };
  };
}
