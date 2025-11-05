{ ... }: {
  services = {
    hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;

        preload = [ "~/.wallpapers/cyberpunk_skull.png" ];

        wallpaper = [ ",~/.wallpapers/cyberpunk_skull.png" ];
      };
    };
  };
}
